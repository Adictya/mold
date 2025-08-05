/* @refresh reload */
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
import Clock from "./Components/Clock";
import StartButton from "./Components/StartButton";

function App() {

  addListener((event) => {
    const {text, key, mods} = event;
    // console.log("Event received:", event);

    if (key == 99 && mods.ctrl) {
      MoldCore.shutdown();
			process.exit(0);
    }
  });

  return (
    <View
      debug_id="Main-div"
      sizing={{
        h: { type: SizingType.Grow },
        w: { type: SizingType.Grow },
      }}
      child_layout={{
        direction: LayoutDirection.topToBottom,
      }}
    >
      <View
        debug_id="Desktop-spacer"
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
          h: { type: SizingType.Fit },
          w: { type: SizingType.Grow },
        }}
        style={{
          bg_color: { hex: "#008080" },
        }}
        // padding={{
        //   top: 1,
        // }}
        // border={{
        //   where: {
        //     top: true,
        //   },
        //   fg_color: { hex: "#dfdfdf" },
        //   bg_color: { hex: "#008080" },
        //   type: BorderType.HugHorizontalFlipped,
        // }}
      >
				<StartButton />
        <View
      		debug_id="Taskbar-spacer"
          style={{
            bg_color: { hex: "#c0c0c0" },
          }}
          sizing={{
            h: { type: SizingType.Grow },
            w: { type: SizingType.Grow },
          }}
        ></View>
        <Clock />
      </View>
    </View>
  );
}

export default App;
