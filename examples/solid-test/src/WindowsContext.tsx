import { createContext, createSignal, type Accessor } from "solid-js";

export const WindowsContext = createContext<{
  notepadOpen: Accessor<boolean>;
  setNotepadOpen: (open: boolean) => boolean;
	startMenuOpen: Accessor<boolean>;
	setStartMenuOpen: (open: any) => boolean;
}>({
  notepadOpen: () => false,
  setNotepadOpen: () => false,
	startMenuOpen: () => false,
	setStartMenuOpen: () => false,
});

export function WindowsProvider(props: { children: any }) {
  const [notepadOpen, setNotepadOpen] = createSignal(false);
	const [startMenuOpen, setStartMenuOpen] = createSignal(false);

  return (
    <WindowsContext.Provider
      value={{
        notepadOpen,
        setNotepadOpen,
				startMenuOpen,
				setStartMenuOpen,
      }}
    >
      {props.children}
    </WindowsContext.Provider>
  );
}
