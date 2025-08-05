const std = @import("std");
const Component = @import("components.zig");

const log = std.log.scoped(.dom);

pub const IdHashMap = std.hash_map.AutoHashMap(u32, *DomNode);

pub var nodeMap: IdHashMap = undefined;

pub var root: ?*DomNode = null;

pub fn init(allocator: std.mem.Allocator) !void {
    log.debug("Initializing DOM", .{});
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
    log.debug("Inserting node {s} into parent {s}", .{ node.component.string_id, parent.component.string_id });

    if (anchor) |a| {
        log.debug("Using anchor {s}", .{a.component.string_id});
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
    log.debug("Removing node {s} from parent {s}", .{ node.component.string_id, parent.component.string_id });

    if (node.previous_sibling) |prev| {
        log.debug("Node has previous sibling {s}", .{prev.component.string_id});
        prev.next_sibling = node.next_sibling;
    } else {
        log.debug("Node is first child, updating parent's first_child", .{});
        parent.first_child = node.next_sibling;
    }

    if (node.next_sibling) |next| {
        log.debug("Node has next sibling {s}", .{next.component.string_id});
        next.previous_sibling = node.previous_sibling;
    }
}

pub fn getParentNode(node: *DomNode) ?*DomNode {
    log.debug("Getting parent of node {s}", .{node.component.string_id});
    if (node.parent) |parent| {
        log.debug("Parent found: {s}", .{parent.component.string_id});
    } else {
        log.debug("No parent found", .{});
    }
    return node.parent;
}

pub fn getFirstChild(node: *DomNode) ?*DomNode {
    log.debug("Getting first child of node {s}", .{node.component.string_id});
    if (node.first_child) |child| {
        log.debug("First child found: {s}", .{child.component.string_id});
    } else {
        log.debug("No children found", .{});
    }
    return node.first_child;
}

pub fn getNextSibling(node: *DomNode) ?*DomNode {
    log.debug("Getting next sibling of node {s}", .{node.component.string_id});
    if (node.next_sibling) |sibling| {
        log.debug("Next sibling found: {s}", .{sibling.component.string_id});
    } else {
        log.debug("No next sibling found", .{});
    }
    return node.next_sibling;
}
