using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;
using Godot;

// Proof of concept: loads dungeon JSON from the Rust generator and lets you walk
// through it, one room per screen. Placeholder until Jip builds the real game.
//
// Run with a different file:  godot --path . -- --dungeon=/abs/path/dungeon.json
// Controls: WASD / arrows to move, R to reload the JSON.
public partial class Main : Node2D
{
    private static readonly string[] Walls = { "top", "bottom", "left", "right" };
    private const float PlayerRadius = 0.35f;
    private const float PlayerSpeed = 6.0f; // tiles per second
    private const float PickupRadius = 0.6f;

    private static readonly Color ColorBg = new("#14141a");
    private static readonly Color ColorFloor = new("#3a3a46");
    private static readonly Color ColorFloorStart = new("#2f4a3a");
    private static readonly Color ColorFloorEnd = new("#4a2f3a");
    private static readonly Color ColorWall = new("#6b6b7d");
    private static readonly Color ColorDoor = new("#c8a040");
    private static readonly Color ColorPlayer = new("#4aa3ff");
    private static readonly Color ColorGoal = new("#e0e0e0");
    private static readonly Color ColorSpawnUnknown = new("#b060e0");
    private static readonly Dictionary<string, Color> SpawnColors = new()
    {
        ["enemy"] = new Color("#e04848"),
        ["health"] = new Color("#48d068"),
        ["ammo"] = new Color("#e0c048"),
    };

    [Export] public string DungeonPath = "res://poc/dungeon.json";

    private DungeonData _dungeon;
    private readonly Dictionary<int, RoomData> _rooms = new();
    private readonly Dictionary<int, List<Door>> _doors = new();
    private readonly Dictionary<int, List<SpawnableData>> _spawns = new();

    private int _currentRoom = -1;
    private Vector2 _player; // room-local, in tiles
    private int _health = 3;
    private int _ammo;
    private bool _finished;
    private string _message = "";

    private Label _hud;

    public override void _Ready()
    {
        var layer = new CanvasLayer();
        AddChild(layer);
        _hud = new Label { Position = new Vector2(12, 8) };
        _hud.AddThemeFontSizeOverride("font_size", 16);
        layer.AddChild(_hud);

        foreach (var arg in OS.GetCmdlineUserArgs())
        {
            if (arg.StartsWith("--dungeon="))
                DungeonPath = arg.Substring("--dungeon=".Length);
        }

        LoadDungeon();
    }

    public override void _UnhandledInput(InputEvent @event)
    {
        if (@event is InputEventKey key && key.Pressed && !key.Echo && key.PhysicalKeycode == Key.R)
            LoadDungeon();
    }

    // ------------------------------------------------------------ loading

    private void LoadDungeon()
    {
        _rooms.Clear();
        _doors.Clear();
        _spawns.Clear();
        _currentRoom = -1;
        _finished = false;
        _health = 3;
        _ammo = 0;
        _message = "";

        string text = FileAccess.GetFileAsString(DungeonPath);
        if (string.IsNullOrEmpty(text))
        {
            Fail($"Could not read {DungeonPath}");
            return;
        }

        try
        {
            _dungeon = JsonSerializer.Deserialize<DungeonData>(text);
        }
        catch (JsonException e)
        {
            Fail($"Invalid JSON in {DungeonPath}: {e.Message}");
            return;
        }

        if (_dungeon == null)
        {
            Fail($"{DungeonPath} is empty");
            return;
        }

        var errors = IndexAndCheck();
        if (errors.Count > 0)
        {
            foreach (var e in errors)
                GD.PushWarning("dungeon.json: " + e);
            _message = $"{errors.Count} problem(s) in JSON, see Output/console";
        }

        if (!_rooms.ContainsKey(_dungeon.StartRoom))
        {
            Fail($"start_room {_dungeon.StartRoom} does not exist");
            return;
        }

        EnterRoom(_dungeon.StartRoom, null);
        GD.Print($"Loaded {DungeonPath}: {_rooms.Count} rooms, {_dungeon.Doors.Count} doors");
    }

    private List<string> IndexAndCheck()
    {
        var errors = new List<string>();

        foreach (var r in _dungeon.Rooms)
        {
            if (_rooms.ContainsKey(r.Id))
                errors.Add($"duplicate room id {r.Id}");
            if (r.Width < 3 || r.Height < 3)
                errors.Add($"room {r.Id} smaller than 3x3 (needs walls + floor)");
            _rooms[r.Id] = r;
            _doors[r.Id] = new List<Door>();
            _spawns[r.Id] = new List<SpawnableData>();
        }

        if (!_rooms.ContainsKey(_dungeon.EndRoom))
            errors.Add("end_room does not exist");

        var raw = _rooms.Keys.ToDictionary(id => id, _ => new List<Door>());
        foreach (var d in _dungeon.Doors)
        {
            if (!_rooms.ContainsKey(d.RoomA) || !_rooms.ContainsKey(d.RoomB))
            {
                errors.Add($"door {d.RoomA}-{d.RoomB} points to a missing room");
                continue;
            }
            if (!Walls.Contains(d.WallA) || !Walls.Contains(d.WallB))
            {
                errors.Add($"door {d.RoomA}-{d.RoomB} has an invalid wall ({d.WallA} / {d.WallB})");
                continue;
            }
            if (Opposite(d.WallA) != d.WallB)
                errors.Add($"door {d.RoomA}-{d.RoomB}: {d.WallA} and {d.WallB} are not opposite walls");

            raw[d.RoomA].Add(new Door { Wall = d.WallA, To = d.RoomB, ToWall = d.WallB });
            raw[d.RoomB].Add(new Door { Wall = d.WallB, To = d.RoomA, ToWall = d.WallA });
        }

        // Several doors on one wall get spread out evenly along it.
        foreach (var (id, list) in raw)
        {
            var room = _rooms[id];
            foreach (var wall in Walls)
            {
                var onWall = list.Where(x => x.Wall == wall).ToList();
                int length = wall is "top" or "bottom" ? room.Width : room.Height;
                for (int i = 0; i < onWall.Count; i++)
                {
                    int offset = (int)((float)length * (i + 1) / (onWall.Count + 1));
                    onWall[i].Offset = Math.Clamp(offset, 1, length - 2);
                    _doors[id].Add(onWall[i]);
                }
            }
        }

        foreach (var s in _dungeon.Spawnables)
        {
            if (!_rooms.TryGetValue(s.Room, out var room))
            {
                errors.Add($"spawnable in missing room {s.Room}");
                continue;
            }
            if (s.X < 1 || s.Y < 1 || s.X > room.Width - 2 || s.Y > room.Height - 2)
                errors.Add($"spawnable {s.Type} at ({s.X},{s.Y}) is not on a floor tile of room {s.Room}");
            _spawns[s.Room].Add(s);
        }

        return errors;
    }

    private static string Opposite(string wall) => wall switch
    {
        "top" => "bottom",
        "bottom" => "top",
        "left" => "right",
        "right" => "left",
        _ => "",
    };

    private void Fail(string text)
    {
        GD.PushError(text);
        _message = text;
        _dungeon = null;
        QueueRedraw();
        UpdateHud();
    }

    // ------------------------------------------------------------ gameplay

    public override void _Process(double delta)
    {
        if (_currentRoom == -1 || _finished)
            return;

        var dir = new Vector2(
            Axis(Key.D, Key.Right) - Axis(Key.A, Key.Left),
            Axis(Key.S, Key.Down) - Axis(Key.W, Key.Up));
        if (dir != Vector2.Zero)
            Move(dir.Normalized() * PlayerSpeed * (float)delta, dir);

        CheckPickups();
        CheckGoal();
        QueueRedraw();
        UpdateHud();
    }

    private static float Axis(Key a, Key b) =>
        Input.IsPhysicalKeyPressed(a) || Input.IsPhysicalKeyPressed(b) ? 1f : 0f;

    private void Move(Vector2 step, Vector2 dir)
    {
        var room = _rooms[_currentRoom];
        float w = room.Width;
        float h = room.Height;
        var target = _player + step;

        foreach (var door in _doors[_currentRoom])
        {
            if (WalkingThrough(door, target, dir, w, h))
            {
                EnterRoom(door.To, door.ToWall);
                return;
            }
        }

        float lo = 1f + PlayerRadius;
        _player = new Vector2(Mathf.Clamp(target.X, lo, w - lo), Mathf.Clamp(target.Y, lo, h - lo));
    }

    private static bool WalkingThrough(Door door, Vector2 target, Vector2 dir, float w, float h)
    {
        float lo = 1f + PlayerRadius;
        float o = door.Offset;
        return door.Wall switch
        {
            "left" => dir.X < 0 && target.X <= lo && target.Y > o && target.Y < o + 1,
            "right" => dir.X > 0 && target.X >= w - lo && target.Y > o && target.Y < o + 1,
            "top" => dir.Y < 0 && target.Y <= lo && target.X > o && target.X < o + 1,
            "bottom" => dir.Y > 0 && target.Y >= h - lo && target.X > o && target.X < o + 1,
            _ => false,
        };
    }

    private void EnterRoom(int id, string throughWall)
    {
        _currentRoom = id;
        var room = _rooms[id];
        float w = room.Width;
        float h = room.Height;
        _player = new Vector2(w / 2f, h / 2f);

        if (throughWall != null)
        {
            var door = _doors[id].FirstOrDefault(d => d.Wall == throughWall);
            if (door != null)
            {
                float o = door.Offset + 0.5f;
                float inside = 1f + PlayerRadius + 0.3f;
                _player = throughWall switch
                {
                    "left" => new Vector2(inside, o),
                    "right" => new Vector2(w - inside, o),
                    "top" => new Vector2(o, inside),
                    _ => new Vector2(o, h - inside),
                };
            }
        }

        QueueRedraw();
        UpdateHud();
    }

    private void CheckPickups()
    {
        var list = _spawns[_currentRoom];
        for (int i = list.Count - 1; i >= 0; i--)
        {
            var s = list[i];
            var pos = new Vector2(s.X + 0.5f, s.Y + 0.5f);
            if (pos.DistanceTo(_player) > PickupRadius)
                continue;

            switch (s.Type)
            {
                case "health":
                    _health += 1;
                    list.RemoveAt(i);
                    break;
                case "ammo":
                    _ammo += 5;
                    list.RemoveAt(i);
                    break;
            }
        }
    }

    private void CheckGoal()
    {
        if (_currentRoom != _dungeon.EndRoom)
            return;
        var room = _rooms[_currentRoom];
        if (_player.DistanceTo(new Vector2(room.Width, room.Height) / 2f) < 0.7f)
        {
            _finished = true;
            _message = "Reached the end room!  Press R to restart.";
        }
    }

    // ------------------------------------------------------------ drawing

    private (Vector2 origin, float tile) Layout()
    {
        var room = _rooms[_currentRoom];
        var view = GetViewportRect().Size;
        var margin = new Vector2(40, 60);
        float tile = Mathf.Min((view.X - margin.X * 2) / room.Width, (view.Y - margin.Y * 2) / room.Height);
        var size = new Vector2(room.Width, room.Height) * tile;
        var origin = (view - size) / 2f + new Vector2(0, 16);
        return (origin, tile);
    }

    public override void _Draw()
    {
        DrawRect(GetViewportRect(), ColorBg);
        if (_currentRoom == -1)
            return;

        var (origin, tile) = Layout();
        var room = _rooms[_currentRoom];
        int w = room.Width;
        int h = room.Height;

        var floorColor = ColorFloor;
        if (_currentRoom == _dungeon.StartRoom)
            floorColor = ColorFloorStart;
        else if (_currentRoom == _dungeon.EndRoom)
            floorColor = ColorFloorEnd;

        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                bool wall = x == 0 || y == 0 || x == w - 1 || y == h - 1;
                DrawRect(new Rect2(origin + new Vector2(x, y) * tile, Vector2.One * tile).Grow(-1), wall ? ColorWall : floorColor);
            }
        }

        foreach (var door in _doors[_currentRoom])
        {
            var cell = door.Wall switch
            {
                "left" => new Vector2(0, door.Offset),
                "right" => new Vector2(w - 1, door.Offset),
                "top" => new Vector2(door.Offset, 0),
                _ => new Vector2(door.Offset, h - 1),
            };
            DrawRect(new Rect2(origin + cell * tile, Vector2.One * tile).Grow(-1), ColorDoor);
            DrawCenteredText(origin + (cell + new Vector2(0.5f, 0.5f)) * tile, door.To.ToString(), tile);
        }

        if (_currentRoom == _dungeon.EndRoom)
            DrawCircle(origin + new Vector2(w, h) / 2f * tile, tile * 0.45f, ColorGoal, false, 3f);

        foreach (var s in _spawns[_currentRoom])
        {
            var c = SpawnColors.TryGetValue(s.Type ?? "", out var col) ? col : ColorSpawnUnknown;
            var p = origin + new Vector2(s.X + 0.5f, s.Y + 0.5f) * tile;
            if (s.Type == "enemy")
                DrawRect(new Rect2(p - Vector2.One * tile * 0.35f, Vector2.One * tile * 0.7f), c);
            else
                DrawCircle(p, tile * 0.3f, c);
        }

        DrawCircle(origin + _player * tile, tile * PlayerRadius, ColorPlayer);
    }

    private void DrawCenteredText(Vector2 center, string text, float tile)
    {
        var font = ThemeDB.FallbackFont;
        int fs = (int)Mathf.Clamp(tile * 0.6f, 8, 28);
        var size = font.GetStringSize(text, HorizontalAlignment.Left, -1, fs);
        DrawString(font, center + new Vector2(-size.X / 2f, size.Y / 3f), text, HorizontalAlignment.Left, -1, fs, Colors.Black);
    }

    private void UpdateHud()
    {
        if (_hud == null)
            return;
        if (_currentRoom == -1)
        {
            _hud.Text = _message;
            return;
        }

        var room = _rooms[_currentRoom];
        string tag = _currentRoom == _dungeon.StartRoom ? "  [START]"
            : _currentRoom == _dungeon.EndRoom ? "  [END]" : "";
        _hud.Text =
            $"Seed {_dungeon.Seed}   Room {_currentRoom} ({room.Width}x{room.Height}){tag}   HP {_health}   Ammo {_ammo}\n" +
            "WASD/arrows move · R reload JSON · yellow = door (number = target room)\n" +
            _message;
    }

    // ------------------------------------------------------------ JSON model

    private class Door
    {
        public string Wall;
        public int Offset;
        public int To;
        public string ToWall;
    }

    private class DungeonData
    {
        [JsonPropertyName("seed")] public long Seed { get; set; }
        [JsonPropertyName("start_room")] public int StartRoom { get; set; }
        [JsonPropertyName("end_room")] public int EndRoom { get; set; }
        [JsonPropertyName("rooms")] public List<RoomData> Rooms { get; set; } = new();
        [JsonPropertyName("doors")] public List<DoorData> Doors { get; set; } = new();
        [JsonPropertyName("spawnables")] public List<SpawnableData> Spawnables { get; set; } = new();
    }

    private class RoomData
    {
        [JsonPropertyName("id")] public int Id { get; set; }
        [JsonPropertyName("x")] public int X { get; set; }
        [JsonPropertyName("y")] public int Y { get; set; }
        [JsonPropertyName("width")] public int Width { get; set; }
        [JsonPropertyName("height")] public int Height { get; set; }
    }

    private class DoorData
    {
        [JsonPropertyName("room_a")] public int RoomA { get; set; }
        [JsonPropertyName("wall_a")] public string WallA { get; set; }
        [JsonPropertyName("room_b")] public int RoomB { get; set; }
        [JsonPropertyName("wall_b")] public string WallB { get; set; }
    }

    private class SpawnableData
    {
        [JsonPropertyName("room")] public int Room { get; set; }
        [JsonPropertyName("type")] public string Type { get; set; }
        [JsonPropertyName("x")] public int X { get; set; }
        [JsonPropertyName("y")] public int Y { get; set; }
    }
}
