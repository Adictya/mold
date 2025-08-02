import MoldCore, {
  addListener,
  AttachPoints,
  BorderType,
  LayoutAlignmentX,
  LayoutAlignmentY,
  LayoutDirection,
  SizingType,
  Text,
  View,
} from "@mold/core";
import { createSignal, createEffect } from "solid-js";

function App() {
  const [val, setVal] = createSignal("_");

  addListener((event) => {
    // console.log("Event received:", event, val());
    const [text, codepoint, mods] = event;

    if (codepoint == 127) {
      setVal((val) => val.slice(0, -1));
    } else {
      setVal((val) => `${val} ${[text, codepoint, mods.ctrl].join(".")}`);
    }
    if (codepoint == 99 && mods.ctrl) {
      MoldCore.shutdown();
    }
  });

  return (
    <View
      padding={{ left: 1, right: 1, top: 1, bottom: 1 }}
      position={{
        offset: { x: 10, y: 15 },
        attach_points: {
          parent: AttachPoints.RightTop,
          element: AttachPoints.RightBottom,
        },
      }}
      child_layout={{
        child_gap: 1,
        child_alignment: {
          x: LayoutAlignmentX.center,
          y: LayoutAlignmentY.top,
        },
        direction: LayoutDirection.leftToRight,
      }}
      scroll={{
        child_offset: { x: 0, y: 0 },
        horizontal: false,
        vertical: false,
      }}
      sizing={{
        w: { minmax: { min: 10, max: 20 }, type: SizingType.Grow },
        h: { minmax: { min: 10 }, type: SizingType.Grow },
      }}
      border={{
        where: {
          top: true,
          bottom: true,
          left: true,
          right: true,
        },
        color: { hex: "#eeeeee" },
        type: BorderType.SingleRounded,
      }}
      style={{
        bg_color: { hex: "#4422ff" },
      }}
    >
      <Text bold>Hello from Solid! {val()}</Text>
    </View>
  );
}

export default App;
