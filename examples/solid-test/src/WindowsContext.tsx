import { createContext, createSignal, type Accessor } from "solid-js";

export const WindowsContext = createContext<{
  notepadOpen: Accessor<boolean>;
  setNotepadOpen: (open: boolean) => boolean;
	startMenuOpen: Accessor<boolean>;
	setStartMenuOpen: (open: any) => boolean;
	errorScene: Accessor<boolean>;
	setErrorScene: (open: any) => boolean;
}>({
  notepadOpen: () => false,
  setNotepadOpen: () => false,
	startMenuOpen: () => false,
	setStartMenuOpen: () => false,
	errorScene: () => false,
	setErrorScene: () => false,
});

export function WindowsProvider(props: { children: any }) {
  const [notepadOpen, setNotepadOpen] = createSignal(false);
	const [startMenuOpen, setStartMenuOpen] = createSignal(false);
	const [errorScene, setErrorScene] = createSignal(false);

  return (
    <WindowsContext.Provider
      value={{
        notepadOpen,
        setNotepadOpen,
				startMenuOpen,
				setStartMenuOpen,
				errorScene,
				setErrorScene,
      }}
    >
      {props.children}
    </WindowsContext.Provider>
  );
}
