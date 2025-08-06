/* @refresh reload */
import WindowsUi from "./Windows98";
import { WindowsProvider } from "./WindowsContext";

function App() {
  return (
    <WindowsProvider>
      <WindowsUi />
    </WindowsProvider>
  );
}

export default App;
