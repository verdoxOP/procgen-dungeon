use crate::edge::Edge;
use crate::room::Room;

// writes the tree as a graphviz .dot file and renders it to tree.png with the `dot` command
pub fn visualize_tree_in_graph_form(tree: &[Edge], rooms: &[Room]) {
    let mut dot = String::from("graph tree {\n    node [shape=box];\n");

    for room in rooms {
        dot.push_str(&format!(
            "    {} [label=\"Room {}\\n{}x{} @ ({},{})\"];\n",
            room.id, room.id, room.width, room.height, room.x, room.y
        ));
    }

    for edge in tree {
        dot.push_str(&format!(
            "    {} -- {} [label=\"{}\"];\n",
            edge.Ivertex1, edge.Ivertex2, edge.weight
        ));
    }

    dot.push_str("}\n");

    std::fs::write("tree.dot", &dot).expect("Failed to write tree.dot");

    match std::process::Command::new("dot")
        .args(["-Tpng", "tree.dot", "-o", "tree.png"])
        .status()
    {
        Ok(status) if status.success() => println!("Tree written to tree.png"),
        _ => {
            println!("Could not run graphviz, tree.dot was still written");
            return;
        }
    }

    // show the png in the terminal
    // inside a (neo)vim terminal real images dont work, so chafa draws it with text blocks instead
    let in_vim = std::env::var("NVIM").is_ok() || std::env::var("VIM_TERMINAL").is_ok();
    let shown = if !in_vim && std::env::var("KITTY_WINDOW_ID").is_ok() {
        std::process::Command::new("kitty")
            .args(["+kitten", "icat", "tree.png"])
            .status()
    } else {
        std::process::Command::new("chafa")
            .args(["--format", "symbols", "tree.png"])
            .status()
    };

    if !matches!(shown, Ok(status) if status.success()) {
        println!("Could not show tree.png in the terminal (is chafa installed?)");
    }
}
