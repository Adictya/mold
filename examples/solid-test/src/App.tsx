/* @refresh reload */
import { createSignal, Match, Switch } from "solid-js";
import WindowsUi from "./Windows98";
import { WindowsProvider } from "./WindowsContext";
import Bootloader from "./Bootloader";
import Loading from "./Loading";

function App() {
  const [route, setRoute] = createSignal("windows98");

	// setTimeout(() => setRoute("loading"), 3000);
	// setTimeout(() => setRoute("windows98"), 7000);

  return (
    <WindowsProvider>
			<Switch>
				<Match when={route() === "bootloader"}>
					<Bootloader />
				</Match>
				<Match when={route() === "loading"}>
					<Loading />
				</Match>
				<Match when={route() === "windows98"}>
					<WindowsUi />
				</Match>
			</Switch>
    </WindowsProvider>
  );
}

export default App;
