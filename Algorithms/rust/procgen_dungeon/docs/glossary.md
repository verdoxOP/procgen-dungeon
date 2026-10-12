# Glossary

[← Documentation home](README.md)

| English | Nederlands | Meaning in this project |
|---|---|---|
| vertex / node | knoop / punt | a room |
| edge | kant / verbinding | a possible door between two rooms |
| weight | gewicht | random cost of an edge, used by Prim |
| graph | graaf | all rooms plus all candidate edges |
| complete graph | volledige graaf | every pair of rooms has an edge |
| undirected | ongericht | an edge works both ways (A–B = B–A) |
| sparse graph | ijle graaf | few edges compared to the number of rooms |
| path | pad | the doors you go through to get from one room to another |
| connected | samenhangend | every room can be reached from every other room |
| cycle | cyclus / kringloop | a path that comes back to where it started |
| tree | boom | connected graph without cycles; n rooms → n − 1 edges |
| spanning tree | opspannende boom | a tree that includes every room |
| minimum spanning tree (MST) | minimaal opspannende boom | spanning tree with the lowest total weight |
| backbone | ruggengraat | the spanning tree; its edges become the doors |
| Prim's algorithm | algoritme van Prim | grows the tree from one room by always adding the cheapest edge from a visited room to a new room |
| Kruskal's algorithm | algoritme van Kruskal | adds the cheapest edges overall, skipping cycles (not used) |
| Union-Find | — | data structure Kruskal uses to detect cycles (not used) |
| adjacency matrix | buurmatrix / adjacentiematrix | n × n table of which rooms are connected |
| edge list / edge set | lijst van kanten | list of all edges with their weights |
| adjacency list | burenlijst / adjacentielijst | per room, the list of rooms it connects to |
| BFS (breadth-first search) | breedte-eerst zoeken | explores rooms layer by layer; gives the number of doors from the start |
| DFS (depth-first search) | diepte-eerst zoeken | explores one path as deep as possible first |
| seed | seed / startwaarde | number that fixes all random choices |
| deterministic | deterministisch | same input → same output |
| rejection sampling | — | generate randomly, throw away results that break a rule |
| tile | tegel | one grid cell; room sizes and positions are in tiles |
| room | kamer | one gameplay chamber = one screen |
| door | deur | a backbone edge; moves the player directly to another room |
| corridor | gang | in this project: a hidden extra edge that creates a cycle |
| spawnable | — | anything placed in a room: enemies, pickups, items |
| population | populatie / vulling | placing spawnables in rooms |
| validation | validatie | checking that generated data follows the rules |
