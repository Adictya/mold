const napigen = @import("napigen");

comptime {
    napigen.defineModule(initModule);
}

fn init(js: *napigen.JsContext, _: napigen.napi_value) anyerror!napigen.napi_value {
    return js.createString("Hello, world!");
}

fn initModule(
    js: *napigen.JsContext,
    exports: napigen.napi_value,
) anyerror!napigen.napi_value {
    try js.setNamedProperty(
        exports,
        "init",
        try js.createFunction(init),
    );

    return exports;
}
