const std = @import("std");
const napigen = @import("napigen");

/// Convert JavaScript object to Zig struct
pub fn jsObjectToStruct(
    comptime T: type,
    js: *napigen.JsContext,
    js_obj: napigen.napi_value,
    result: *T,
    allocator: std.mem.Allocator,
) !void {
    const env = js.env;
    const type_info = @typeInfo(T);
    // if (type_info != .Struct) {
    //     @compileError("T must be a struct type");
    // }

    inline for (type_info.@"struct".fields) |field| {
        const js_value = js.getNamedProperty(js_obj, field.name) catch
            js.null() catch undefined;

        const field_ptr = &@field(result, field.name);

        const undef = js.undefined() catch undefined;

        switch (@typeInfo(field.type)) {
            .int => |int_info| {
                if (js_value == undef) {
                    @field(result, field.name) = 0;
                    return;
                }

                if (int_info.signedness == .signed) {
                    _ = napigen.napi_get_value_int32(env, js_value, @ptrCast(@alignCast(field_ptr)));
                } else {
                    _ = napigen.napi_get_value_uint32(env, js_value, @ptrCast(@alignCast(field_ptr)));
                }
            },
            .float => {
                if (js_value == undef) {
                    @field(result, field.name) = 0.0;
                    return;
                }
                _ = napigen.napi_get_value_double(env, js_value, @ptrCast(@alignCast(field_ptr)));
            },
            .bool => {
                if (js_value == undef) {
                    @field(result, field.name) = false;
                    return;
                }
                _ = napigen.napi_get_value_bool(env, js_value, @ptrCast(@alignCast(field_ptr)));
            },
            .pointer => |ptr_info| {
                if (ptr_info.size == .one and ptr_info.child == u8) {
                    // Handle null-terminated string (const char*)
                    if (js_value == undef) {
                        @field(result, field.name) = null;
                        return;
                    }

                    var text_buffer: [256]u8 = undefined;
                    var text_length: usize = 0;
                    const status = napigen.napi_get_value_string_utf8(env, js_value, &text_buffer, text_buffer.len, &text_length);

                    if (status == napigen.napi_ok and text_length > 0) {
                        const text_copy = allocator.allocSentinel(u8, text_length, 0) catch {
                            @field(result, field.name) = null;
                            return;
                        };
                        @memcpy(text_copy, text_buffer[0..text_length]);
                        @field(result, field.name) = text_copy.ptr;
                    } else {
                        @field(result, field.name) = null;
                    }
                } else if (ptr_info.size == .slice and ptr_info.child == u8) {
                    // Handle string slice ([]const u8)
                    if (js_value == undef) {
                        @field(result, field.name) = "";
                        return;
                    }

                    var text_buffer: [256]u8 = undefined;
                    var text_length: usize = 0;
                    const status = napigen.napi_get_value_string_utf8(env, js_value, &text_buffer, text_buffer.len, &text_length);

                    if (status == napigen.napi_ok and text_length > 0) {
                        const text_copy = allocator.alloc(u8, text_length) catch {
                            @field(result, field.name) = "";
                            return;
                        };
                        @memcpy(text_copy, text_buffer[0..text_length]);
                        @field(result, field.name) = text_copy;
                    } else {
                        @field(result, field.name) = "";
                    }
                }
            },
            .optional => |opt_info| {
                if (js_value == undef) {
                    @field(result, field.name) = null;
                    return;
                }

                var value_type: napigen.napi_valuetype = undefined;
                _ = napigen.napi_typeof(env, js_value, &value_type);

                if (value_type == napigen.napi_null) {
                    @field(result, field.name) = null;
                } else {
                    switch (@typeInfo(opt_info.child)) {
                        .int => |int_info| {
                            var temp_value: opt_info.child = undefined;
                            if (int_info.signedness == .signed) {
                                _ = napigen.napi_get_value_int32(env, js_value, @ptrCast(@alignCast(&temp_value)));
                            } else {
                                _ = napigen.napi_get_value_uint32(env, js_value, @ptrCast(@alignCast(&temp_value)));
                            }
                            @field(result, field.name) = temp_value;
                        },
                        .float => {
                            var temp_value: opt_info.child = undefined;
                            _ = napigen.napi_get_value_double(env, js_value, @ptrCast(@alignCast(&temp_value)));
                            @field(result, field.name) = temp_value;
                        },
                        .bool => {
                            var temp_value: opt_info.child = undefined;
                            _ = napigen.napi_get_value_bool(env, js_value, @ptrCast(@alignCast(&temp_value)));
                            @field(result, field.name) = temp_value;
                        },
                        .pointer => |ptr_info_inner| {
                            if (ptr_info_inner.size == .one and ptr_info_inner.child == u8) {
                                // Handle optional null-terminated string
                                var text_buffer: [256]u8 = undefined;
                                var text_length: usize = 0;
                                const status = napigen.napi_get_value_string_utf8(env, js_value, &text_buffer, text_buffer.len, &text_length);

                                if (status == napigen.napi_ok and text_length > 0) {
                                    const text_copy = allocator.allocSentinel(u8, text_length, 0) catch {
                                        @field(result, field.name) = null;
                                        return;
                                    };
                                    @memcpy(text_copy, text_buffer[0..text_length]);
                                    @field(result, field.name) = text_copy.ptr;
                                } else {
                                    @field(result, field.name) = null;
                                }
                            } else if (ptr_info_inner.size == .slice and ptr_info_inner.child == u8) {
                                // Handle optional string slice
                                var text_buffer: [256]u8 = undefined;
                                var text_length: usize = 0;
                                const status = napigen.napi_get_value_string_utf8(env, js_value, &text_buffer, text_buffer.len, &text_length);

                                if (status == napigen.napi_ok and text_length > 0) {
                                    const text_copy = allocator.alloc(u8, text_length) catch {
                                        @field(result, field.name) = null;
                                        return;
                                    };
                                    @memcpy(text_copy, text_buffer[0..text_length]);
                                    @field(result, field.name) = text_copy;
                                } else {
                                    @field(result, field.name) = null;
                                }
                            }
                        },
                        .@"struct" => {
                            var temp_value: opt_info.child = undefined;
                            try jsObjectToStruct(opt_info.child, env, js_value, &temp_value, allocator);
                            @field(result, field.name) = temp_value;
                        },
                        else => {
                            @compileError("Unsupported optional field type: " ++
                                @typeName(opt_info.child));
                        },
                    }
                }
            },
            .@"enum" => |enum_info| {
                if (js_value == undef) {
                    @field(result, field.name) = @enumFromInt(0);
                    return;
                }

                var int_value: u32 = 0;
                _ = napigen.napi_get_value_uint32(env, js_value, &int_value);
                @field(result, field.name) = @enumFromInt(@as(enum_info.tag_type, @intCast(int_value)));
            },
            .@"struct" => {
                if (js_value == undef) return;
                try jsObjectToStruct(field.type, env, js_value, field_ptr, allocator);
            },
            else => {
                // @compileError("Unsupported field type: " ++ @typeName(field.type));
            },
        }
    }
}

/// Convert Zig struct to JavaScript object
pub fn structToJsObject(
    comptime T: type,
    env: napigen.napi_env,
    value: *T,
) !napigen.napi_value {
    const type_info = @typeInfo(T);
    if (type_info != .@"struct") {
        @compileError("T must be a struct type");
    }

    var js_obj: napigen.napi_value = null;
    _ = napigen.napi_create_object(env, &js_obj);

    inline for (type_info.@"struct".fields) |field| {
        const field_value = @field(value, field.name);
        var js_value: napigen.napi_value = undefined;

        switch (@typeInfo(field.type)) {
            .int => |int_info| {
                if (int_info.signedness == .signed) {
                    _ = napigen.napi_create_int32(env, @intCast(field_value), &js_value);
                } else {
                    _ = napigen.napi_create_uint32(env, @intCast(field_value), &js_value);
                }
            },
            .float => {
                _ = napigen.napi_create_double(env, @floatCast(field_value), &js_value);
            },
            .bool => {
                _ = napigen.napi_get_boolean(env, field_value, &js_value);
            },
            .pointer => |ptr_info| {
                if (ptr_info.size == .one and ptr_info.child == u8) {
                    // Handle null-terminated string
                    if (field_value == null) {
                        _ = napigen.napi_get_null(env, &js_value);
                    } else {
                        const len = std.mem.len(field_value);
                        _ = napigen.napi_create_string_utf8(env, field_value, len, &js_value);
                    }
                } else if (ptr_info.size == .slice and ptr_info.child == u8) {
                    // Handle string slice
                    _ = napigen.napi_create_string_utf8(env, field_value.ptr, field_value.len, &js_value);
                }
            },
            .optional => {
                if (field_value) |val| {
                    switch (@typeInfo(@TypeOf(val))) {
                        .int => |int_info| {
                            if (int_info.signedness == .signed) {
                                _ = napigen.napi_create_int32(env, @intCast(val), &js_value);
                            } else {
                                _ = napigen.napi_create_uint32(env, @intCast(val), &js_value);
                            }
                        },
                        .float => {
                            _ = napigen.napi_create_double(env, @floatCast(val), &js_value);
                        },
                        .bool => {
                            _ = napigen.napi_get_boolean(env, val, &js_value);
                        },
                        .pointer => |ptr_info| {
                            if (ptr_info.size == .one and ptr_info.child == u8) {
                                const len = std.mem.len(val);
                                _ = napigen.napi_create_string_utf8(env, val, len, &js_value);
                            } else if (ptr_info.size == .slice and ptr_info.child == u8) {
                                _ = napigen.napi_create_string_utf8(env, val.ptr, val.len, &js_value);
                            }
                        },
                        .@"struct" => {
                            js_value = try structToJsObject(@TypeOf(val), env, @constCast(&val));
                        },
                        else => {
                            @compileError("Unsupported optional field type: " ++
                                @typeName(@TypeOf(val)));
                        },
                    }
                } else {
                    _ = napigen.napi_get_null(env, &js_value);
                }
            },
            .@"enum" => {
                _ = napigen.napi_create_uint32(env, @intFromEnum(field_value), &js_value);
            },
            .@"struct" => {
                js_value = try structToJsObject(field.type, env, @constCast(&field_value));
            },
            else => {
                // @compileError("Unsupported field type: " ++ @typeName(field.type));
            },
        }

        _ = napigen.napi_set_named_property(env, js_obj, field.name, js_value);
    }

    return js_obj;
}
