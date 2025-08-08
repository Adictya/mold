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
  Show,
  log,
  useDragContext,
} from "@mold/core";
import Clock from "./Components/Clock";
import StartButton from "./Components/StartButton";
import Colors from "./styleSheet";
import Notepad from "./Components/Notepad";
import { WindowsContext, WindowsProvider } from "./WindowsContext";
import { createSignal, useContext } from "solid-js";
import ErrorsGalore from "./Components/ErrorsGalore";

function App() {
  const draggContext = useDragContext();
  const { notepadOpen, setNotepadOpen, setStartMenuOpen } =
    useContext(WindowsContext);
  addListener((event) => {
    const { text, key, mods } = event;
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
      onMouse={draggContext.handleAreaMouse}
    >
      <Show when={notepadOpen()}>
        <Notepad />
      </Show>
      <ErrorsGalore />
      <View
        debug_id="Desktop-spacer"
        sizing={{
          h: { type: SizingType.Grow },
          w: { type: SizingType.Grow },
        }}
        style={{
          bg_color: { hex: Colors.desktopBackground },
        }}
        onClick={() => setStartMenuOpen(false)}
      />
      <View
        debug_id="Taskbar"
        sizing={{
          h: { type: SizingType.Fit },
          w: { type: SizingType.Grow },
        }}
        style={{
          bg_color: { hex: Colors.desktopBackground },
        }}
      >
        <StartButton />
        <View
          debug_id="Taskbar-spacer-container"
          sizing={{
            h: { minmax: { min: 2, max: 2 } },
            w: { type: SizingType.Grow },
          }}
          child_layout={{
            direction: LayoutDirection.topToBottom,
          }}
        >
          <View
            debug_id="Taskbar-spacer-top-border"
            sizing={{
              h: { minmax: { min: 1, max: 1 } },
              w: { type: SizingType.Grow },
            }}
            style={{
              bg_color: { hex: Colors.desktopBackground },
            }}
            border={{
              where: {
                top: true,
              },
              fg_color: { hex: Colors.lightBorder },
              type: BorderType.HugHorizontalFlipped,
            }}
          ></View>
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
        </View>
        <Clock />
      </View>
    </View>
  );
}

export default App;
