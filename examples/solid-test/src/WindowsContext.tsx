import { useDraggable, type MouseEventHandler } from "@mold/core";
import { createContext, createSignal, type Accessor } from "solid-js";

export const WindowsContext = createContext<{
  notepadOpen: Accessor<boolean>;
  setNotepadOpen: (open: boolean) => boolean;
  startMenuOpen: Accessor<boolean>;
  setStartMenuOpen: (open: any) => boolean;
  errorScene: Accessor<boolean>;
  setErrorScene: (open: any) => boolean;
  notepadDraggable: ReturnType<typeof useDraggable>;
}>({
  notepadOpen: () => false,
  setNotepadOpen: () => false,
  startMenuOpen: () => false,
  setStartMenuOpen: () => false,
  errorScene: () => false,
  setErrorScene: () => false,
  notepadDraggable: (() => ({
    position: () => ({ x: 0, y: 0 }),
    updatePosition: () => {},
    size: () => ({ x: 0, y: 0 }),
    handleMouse: () => {},
    isDragging: () => false,
  })) as any,
});

export function WindowsProvider(props: { children: any }) {
  const [notepadOpen, setNotepadOpen] = createSignal(false);
  const [startMenuOpen, setStartMenuOpen] = createSignal(false);
  const [errorScene, setErrorScene] = createSignal(false);
  const notepadDraggable = useDraggable(
    "notepad",
    { x: 10, y: 5 },
    { x: 60, y: 8 },
  );

  return (
    <WindowsContext.Provider
      value={{
        notepadOpen,
        setNotepadOpen,
        startMenuOpen,
        setStartMenuOpen,
        errorScene,
        setErrorScene,
        notepadDraggable,
      }}
    >
      {props.children}
    </WindowsContext.Provider>
  );
}
