import { For, LayoutDirection, Text, View } from "@mold/core";
import { createSignal, onCleanup } from "solid-js";

const checks = [
  "BIOS v3.21 Build 980515",
  "System Initiating Self-Test...",
  "Memory Test: 000000KB OK", // This will count up in animation
  "Memory Test: 000512KB OK",
  "Memory Test: 001024KB OK",
  "Memory Test: 002048KB OK",
  "Memory Test: 004096KB OK",
  "Memory Test: 008192KB OK",
  "Memory Test: 016384KB OK",
  "Memory Test: 032768KB OK",
  "Memory Test: 065536KB OK",
  "Memory Test: 131072KB OK",
  "Memory Test: 262144KB OK",
  "Memory Test: 524288KB OK", // Or whatever max memory you want to simulate
  "", // Blank line for spacing
  "Detecting IDE Primary Master   ... DATASTREAM HD-7200FX",
  "Detecting IDE Primary Slave    ... OPTICAL DRIVE CX-ROM 48X",
  "Detecting IDE Secondary Slave  ... SUPERDRIVE RW-9000",
  "Detecting ATA Port 3           ... DATASTREAM HD-4000FX",
  "Detecting IDE Primary Master   ... DATASTREAM HD-7200FX",
  "Detecting ATA Port 4           ... ZIPPER DRV ATAPI",
  "Detecting ATA Port 3           ... DATASTREAM HD-4000FX",
  "Detecting ATA Port 4           ... ZIPPER DRV ATAPI",
  "Detecting IDE Primary Master   ... DATASTREAM HD-7200FX",
  "Detecting IDE Primary Slave    ... OPTICAL DRIVE CX-ROM 48X",
  "Detecting IDE Secondary Master ... DATASTREAM HD-12000FX",
  "Detecting IDE Secondary Slave  ... SUPERDRIVE RW-9000",
  "Detecting IDE Primary Master   ... DATASTREAM HD-7200FX",
  "Detecting IDE Primary Slave    ... OPTICAL DRIVE CX-ROM 48X",
  "Detecting IDE Secondary Master ... DATASTREAM HD-12000FX",
  "Detecting IDE Secondary Slave  ... SUPERDRIVE RW-9000",
  "Detecting IDE Secondary Master ... DATASTREAM HD-12000FX",
  "Detecting IDE Primary Slave    ... OPTICAL DRIVE CX-ROM 48X",
  "Detecting IDE Secondary Master ... DATASTREAM HD-12000FX",
  "Detecting IDE Secondary Slave  ... SUPERDRIVE RW-9000",
  "Detecting ATA Port 3           ... DATASTREAM HD-4000FX",
  "Detecting ATA Port 4           ... ZIPPER DRV ATAPI",
  "Detecting ATA Port 3           ... DATASTREAM HD-4000FX",
  "Detecting ATA Port 4           ... ZIPPER DRV ATAPI",
  "", // Blank line for spacing
  "Verifying DMI Pool Data.........",
  "Booting from Local Disk...",
  "", // Blank line for spacing
  "Loading Operating System...",
  "Starting System Kernel...",
  "Loading CORE modules...",
  "Initializing Device Drivers...",
  "", // Blank line for spacing
  "Starting Windows 98...", // This is the final line before graphical splash
];

const keyframes = [
  // BIOS header
  2, 3, 4, 5, 6, 7, 8, 9,

  // pause after memory test series
  13, 13, 15, 15,

  // device detection – a short pause after each group
  24, 24, 25, 26, 27, 27,

  // pause before DMI verification
  38, 38, 40, 41, 41, 45, 45,
];

export default function Bootloader() {
  const [showUpto, setShowUpto] = createSignal(0);
  var index = 0;

  const interval = setInterval(() => {
    if (index < keyframes.length) {
      setShowUpto(keyframes[index]);
      index++;
    } else {
      clearInterval(interval);
    }
  }, 100);

  const logs = () => checks.slice(0, showUpto());

  onCleanup(() => {
    clearInterval(interval);
  });
  return (
    <View
      debug_id="Bootloader-container"
      child_layout={{
        direction: LayoutDirection.topToBottom,
      }}
      scroll={{
        vertical: true,
      }}
    >
      <Text fg_color={{ hex: "#fff" }}>
        MOLDOWS(C)1998 Touvolu Megatrends Inc.
      </Text>
      <Text fg_color={{ hex: "#fff" }}>
        A586B/PRO-A, K2-350 AT/Desktop SYSTEM
      </Text>
      <Text fg_color={{ hex: "#fff" }}>Press DEL to enter SETUP</Text>
      <Text fg_color={{ hex: "#fff" }}> </Text>
      <Text fg_color={{ hex: "#fff" }}>Checking NVRAM..</Text>
      <Text fg_color={{ hex: "#fff" }}> </Text>
      <Text fg_color={{ hex: "#fff" }}>0065536 KB OK</Text>
      <For each={logs()}>
        {(check, i) => (
          <Text fg_color={{ hex: "#fff" }}>
            {check}
          </Text>
        )}
      </For>
    </View>
  );
}
