import MoldCore, {
  addListener,
  AttachPoints,
  BorderType,
  LayoutAlignmentX,
  LayoutAlignmentY,
  LayoutDirection,
  SizingType,
  Text,
  UnderlineType,
  View,
} from "@mold/core";
import { createSignal, onCleanup } from "solid-js";

function getCurrentTime() {
  const now = new Date();
  const hours = String(now.getHours()).padStart(2, "0");
  const minutes = String(now.getMinutes()).padStart(2, "0");
  const seconds = String(now.getSeconds()).padStart(2, "0");
  // const millis = String(now.getMilliseconds()).padStart(4, "0");

  return `${hours}:${minutes}:${seconds}`;
  // return `${hours}:${minutes}:${seconds}:${millis}`;
}

function App() {
  addListener((event) => {
    const {text, key, mods} = event;
    console.log("Event received:", event);

    if (key == 99 && mods.ctrl) {
      MoldCore.shutdown();
    }
  });

  const [time, setTime] = createSignal(getCurrentTime());
  const [counter, setCounter] = createSignal(0);

  const interval = setInterval(() => {
    // setTime(getCurrentTime());
  }, 1000);

  onCleanup(() => {
    clearInterval(interval);
  });

  return (
    <View
      sizing={{
        h: { type: SizingType.Grow },
        w: { type: SizingType.Grow },
      }}
      child_layout={{
        direction: LayoutDirection.topToBottom,
      }}
    >
      <View
        sizing={{
          h: { type: SizingType.Grow },
          w: { type: SizingType.Grow },
        }}
        style={{
          bg_color: { hex: "#008080" },
        }}
      />
      <View
        debug_id="Taskbar"
        sizing={{
          h: { minmax: { min: 2, max: 2 }, type: SizingType.Fixed },
          w: { type: SizingType.Grow },
        }}
        style={{
          bg_color: { hex: "#c0c0c0" },
        }}
        padding={{
          top: 1,
        }}
        border={{
          where: {
            top: true,
          },
          fg_color: { hex: "#dfdfdf" },
          bg_color: { hex: "#008080" },
          type: BorderType.HugHorizontalFlipped,
        }}
      >
        <View
          style={{
            bg_color: { hex: "#c0c0c0" },
          }}
          border={{
            where: {
              left: true,
            },
            fg_color: { hex: "#dfdfdf" },
            type: BorderType.HugVerticalFlipped,
          }}
          padding={{
            left: 1,
          }}
          onClick={() => {
            setTime(getCurrentTime());
            setCounter((count)=> count + 1);
          }}
        >
          <Text
            debug_id="text1"
            fg_color={{ hex: "#222" }}
            bold
            ul_style={UnderlineType.Double}
            ul_color={{ hex: "#3c3c3c" }}
          >
            ⛴︎ Start {counter()}
          </Text>
          <Text
            debug_id="text2"
            fg_color={{ hex: "#3c3c3c" }}
            bold
            ul_style={UnderlineType.Double}
            ul_color={{ hex: "#3c3c3c" }}
          >
            ▐
          </Text>
        </View>
        <View
          style={{
            bg_color: { hex: "#c0c0c0" },
          }}
          sizing={{
            h: { type: SizingType.Grow },
            w: { type: SizingType.Grow },
          }}
        ></View>
        <View
          style={{
            bg_color: { hex: "#c0c0c0" },
          }}
          border={{
            where: {
              left: true,
            },
            fg_color: { hex: "#6d6d6d" },
            type: BorderType.HugVerticalFlipped,
          }}
          padding={{
            left: 1,
          }}
        >
          <Text
            fg_color={{ hex: "#222" }}
            bg_color={{ hex: "#c0c0c0" }}
            bold
            ul_style={UnderlineType.Double}
            ul_color={{ hex: "#dfdfdf" }}
          >
            ⏲  {time()}
          </Text>
          <Text
            fg_color={{ hex: "#dfdfdf" }}
            bg_color={{ hex: "#c0c0c0" }}
            bold
          >
            ▐
          </Text>
        </View>
      </View>
    </View>
  );
}

export default App;
