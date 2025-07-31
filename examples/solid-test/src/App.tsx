import { addListener } from "@mold/core";
import { createSignal, createEffect } from "solid-js";

function App() {
  const [val, setVal] = createSignal("_");

  addListener((event) => {
    // console.log("Event received:", event, val());
    const [text, codepoint, mods] = event;
    setVal((val) => `${val} ${text}(${codepoint})`);
    if (text === "C") {
      process.exit(0);
    }
  });

  return (
    <div height="20" width="20" bgColor="#ff0000" fgColor="#00ff00">
      Mold {"<3"} Solid {val()}
    </div>
  );
}

export default App;
