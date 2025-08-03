const std = @import("std");
const Component = @import("components.zig");

pub const IdHashMap = std.hash_map.AutoHashMap(u32, *DomNode);

pub var nodeMap: IdHashMap = undefined;

pub var root: ?*DomNode = null;

pub fn init(allocator: std.mem.Allocator) !void {
    nodeMap = std.hash_map.AutoHashMap(u32, *DomNode).init(allocator);
}

pub const DomNode = struct {
    component: *Component,
    parent: ?*DomNode = null,
    first_child: ?*DomNode = null,
    next_sibling: ?*DomNode = null,
    previous_sibling: ?*DomNode = null,
};

pub fn insertNode(parent: *DomNode, node: *DomNode, anchor: ?*DomNode) void {
    if (anchor) |a| {
        node.previous_sibling = a;
        node.next_sibling = a.next_sibling;
        if (a.next_sibling) |next| {
            next.previous_sibling = node;
        }
        a.next_sibling = node;
    } else {
        // Insert at the end of the children list
        if (parent.first_child) |first| {
            // Find the last child
            var last = first;
            while (last.next_sibling) |next| {
                last = next;
            }
            // Insert after the last child
            node.previous_sibling = last;
            node.next_sibling = null;
            last.next_sibling = node;
        } else {
            // No children yet, this becomes the first child
            node.previous_sibling = null;
            node.next_sibling = null;
            parent.first_child = node;
        }
    }
    node.parent = parent;
}

pub fn removeNode(parent: *DomNode, node: *DomNode) void {
    if (node.previous_sibling) |prev| {
        prev.next_sibling = node.next_sibling;
    } else {
        parent.first_child = node.next_sibling;
    }

    if (node.next_sibling) |next| {
        next.previous_sibling = node.previous_sibling;
    }
}

pub fn getParentNode(node: *DomNode) ?*DomNode {
    return node.parent;
}

pub fn getFirstChild(node: *DomNode) ?*DomNode {
    return node.first_child;
}

pub fn getNextSibling(node: *DomNode) ?*DomNode {
    return node.next_sibling;
}
