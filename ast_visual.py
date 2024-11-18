from graphviz import Digraph
import re
import uuid
from typing import Optional, List, Tuple

class TreeNode:
    def __init__(self, content: str):
        self.content = content
        self.children: List[TreeNode] = []
        self.id = str(uuid.uuid4())

def parse_tree_line(line: str) -> Tuple[int, str]:
    """
    Parse a line from the syntax tree file to extract indentation level and content.
    Returns tuple of (indent_level, content)
    """
    # Count the number of spaces before the first '├──' or other content
    indent_match = re.match(r'^(\s*)(├── )?(.+)$', line)
    if indent_match:
        indent = indent_match.group(1)
        content = indent_match.group(3)
        return (len(indent) // 2, content.strip())
    return (0, line.strip())

def build_tree(lines: List[str]) -> Optional[TreeNode]:
    """Build a tree structure from the input lines"""
    if not lines:
        return None

    # Skip header and find first actual node
    start_index = -1
    for i, line in enumerate(lines):
        if 'Operation: MStmts' in line:
            start_index = i
            break
    
    if start_index == -1:
        return None

    # Start with the first actual node
    root = TreeNode(lines[start_index].replace('├── ', '').strip())
    stack = [(0, root)]
    
    for line in lines[start_index + 1:]:
        if not line.strip():
            continue
            
        level, content = parse_tree_line(line)
        
        # Create new node
        node = TreeNode(content)
        
        # Find parent
        while stack and stack[-1][0] >= level:
            stack.pop()
            
        if stack:
            stack[-1][1].children.append(node)
            
        stack.append((level, node))
        
    return root

def create_visualization(root: TreeNode, filename: str = "syntax_tree"):
    """Create and save the tree visualization"""
    dot = Digraph(comment='Syntax Tree Visualization')
    dot.attr(rankdir='TB')
    dot.attr('node', shape='box', style='rounded', fontname='Arial')
    
    def add_nodes_edges(node: TreeNode):
        """Recursively add nodes and edges to the graph"""
        # Set node color based on content type
        if 'Operation:' in node.content:
            dot.node(node.id, node.content, fillcolor='lightblue', style='filled,rounded')
        elif 'Variable:' in node.content:
            dot.node(node.id, node.content, fillcolor='lightgreen', style='filled,rounded')
        elif 'Value:' in node.content:
            dot.node(node.id, node.content, fillcolor='lightyellow', style='filled,rounded')
        else:
            dot.node(node.id, node.content)
        
        for child in node.children:
            add_nodes_edges(child)
            dot.edge(node.id, child.id)
    
    add_nodes_edges(root)
    
    try:
        dot.render(filename, view=True, format='png', cleanup=True)
        print(f"Tree visualization has been saved as '{filename}.png'")
    except Exception as e:
        print(f"Error generating visualization: {e}")

def main():
    try:
        # Read the input file
        input_file = "outputs/syn_tree_output.txt"
        with open(input_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # Build the tree
        root = build_tree(lines)
        if root:
            # Create visualization
            create_visualization(root, "syntax_tree")
        else:
            print("No valid tree structure found in the input file")
            
    except FileNotFoundError:
        print(f"Error: Could not find the file '{input_file}'")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()


# from graphviz import Digraph
# import re
# import uuid
# from typing import Optional, List, Dict, Tuple

# class TreeNode:
#     def __init__(self, content: str):
#         self.content = content
#         self.children: List[TreeNode] = []
#         self.id = str(uuid.uuid4())

# def parse_tree_line(line: str) -> Tuple[int, str]:
#     """
#     Parse a line from the syntax tree file to extract indentation level and content.
#     Returns tuple of (indent_level, content)
#     """
#     # Count the number of spaces before the first '├──' or other content
#     indent_match = re.match(r'^(\s*)(├── )?(.+)$', line)
#     if indent_match:
#         indent = indent_match.group(1)
#         content = indent_match.group(3)
#         return (len(indent) // 2, content.strip())  # Divide by 2 since each level is 2 spaces
#     return (0, line.strip())

# def build_tree(lines: List[str]) -> Optional[TreeNode]:
#     """Build a tree structure from the input lines"""
#     if not lines:
#         return None

#     # Remove header lines
#     while lines and ('=' in lines[0] or not lines[0].strip()):
#         lines.pop(0)
    
#     if not lines:
#         return None

#     root = TreeNode(lines[0].strip())
#     stack = [(0, root)]
    
#     for line in lines[1:]:
#         if not line.strip():
#             continue
            
#         level, content = parse_tree_line(line)
        
#         # Create new node
#         node = TreeNode(content)
        
#         # Find parent
#         while stack and stack[-1][0] >= level:
#             stack.pop()
            
#         if stack:
#             stack[-1][1].children.append(node)
            
#         stack.append((level, node))
        
#     return root

# def create_visualization(root: TreeNode, filename: str = "syntax_tree"):
#     """Create and save the tree visualization"""
#     dot = Digraph(comment='Syntax Tree Visualization')
#     dot.attr(rankdir='TB')
#     dot.attr('node', shape='box', style='rounded', fontname='Arial')
    
#     def process_node_content(content: str) -> str:
#         """Process node content for better visualization"""
#         # Extract operation/variable/value
#         if 'Operation:' in content:
#             return content
#         elif 'Variable:' in content:
#             return content
#         elif 'Value:' in content:
#             return content
#         return content

#     def add_nodes_edges(node: TreeNode):
#         """Recursively add nodes and edges to the graph"""
#         node_label = process_node_content(node.content)
        
#         # Set node color based on content type
#         if 'Operation:' in node.content:
#             dot.node(node.id, node_label, fillcolor='lightblue', style='filled,rounded')
#         elif 'Variable:' in node.content:
#             dot.node(node.id, node_label, fillcolor='lightgreen', style='filled,rounded')
#         elif 'Value:' in node.content:
#             dot.node(node.id, node_label, fillcolor='lightyellow', style='filled,rounded')
#         else:
#             dot.node(node.id, node_label)
        
#         for child in node.children:
#             add_nodes_edges(child)
#             dot.edge(node.id, child.id)
    
#     add_nodes_edges(root)
    
#     try:
#         dot.render(filename, view=True, format='png', cleanup=True)
#         print(f"Tree visualization has been saved as '{filename}.png'")
#     except Exception as e:
#         print(f"Error generating visualization: {e}")

# def main():
#     try:
#         # Read the input file
#         input_file = "outputs/ast_input.txt"
#         with open(input_file, 'r') as f:
#             lines = f.readlines()
        
#         # Build the tree
#         root = build_tree(lines)
#         if root:
#             # Create visualization
#             create_visualization(root, "syntax_tree")
#         else:
#             print("No valid tree structure found in the input file")
            
#     except FileNotFoundError:
#         print(f"Error: Could not find the file '{input_file}'")
#     except Exception as e:
#         print(f"An error occurred: {e}")

# if __name__ == "__main__":
#     main()