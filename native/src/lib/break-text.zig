const std = @import("std");

pub fn breakLongWords(
    allocator: std.mem.Allocator,
    input: []const u8,
    maxWidth: usize,
) ![]const u8 {
    // if (true) return input;
    // return input;
    if (maxWidth == 0) {
        return error.InvalidMaxWidth;
    }

    if (input.len == 0) {
        return allocator.alloc(u8, 0);
    }

    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    var cursor: usize = 0;
    while (cursor < input.len) {
        var word_start = cursor;
        while (word_start < input.len and std.ascii.isWhitespace(input[word_start])) {
            word_start += 1;
        }

        try result.appendSlice(input[cursor..word_start]);

        var word_end = word_start;
        while (word_end < input.len and !std.ascii.isWhitespace(input[word_end])) {
            word_end += 1;
        }

        const word = input[word_start..word_end];

        if (word.len > maxWidth) {
            var i: usize = 0;
            while (i + maxWidth < word.len) {
                try result.appendSlice(word[i .. i + maxWidth]);
                try result.append(' '); // Insert the space.
                i += maxWidth;
            }
            try result.appendSlice(word[i..]);
        } else {
            try result.appendSlice(word);
        }

        cursor = word_end;
    }

    return result.toOwnedSlice();
}

test "basic case: a single very long word" {
    const testingAllocator = std.testing.allocator;
    const input = "supercalifragilisticexpialidocious";
    const expected = "supercalif ragilistic expialidoc ious";
    const actual = try breakLongWords(testingAllocator, input, 10);
    defer testingAllocator.free(actual);
    try std.testing.expectEqualStrings(expected, actual);
}

test "basic case: mixed with short words and varied whitespace" {
    const testingAllocator = std.testing.allocator;
    const input = "Hello  there thisisanotherlongword indeed";
    const expected = "Hello  there thisi sanot herlo ngwor d indee d";
    const actual = try breakLongWords(testingAllocator, input, 5);
    defer testingAllocator.free(actual);
    try std.testing.expectEqualStrings(expected, actual);
}

test "basic case: no long words" {
    const testingAllocator = std.testing.allocator;
    const input = "these words are all fine";
    const expected = "these words are all fine";
    const actual = try breakLongWords(testingAllocator, input, 6);
    defer testingAllocator.free(actual);
    try std.testing.expectEqualStrings(expected, actual);
}
