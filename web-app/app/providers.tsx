// app/providers.tsx
"use client";

import { ChakraProvider, extendTheme } from "@chakra-ui/react";

// Define a custom theme
const theme = extendTheme({
  styles: {
    global: {
      body: {
        color: "#070F2B",
      },
    },
  },
});

export function Providers({ children }: { children: React.ReactNode }) {
  // Provide the custom theme to your application
  return <ChakraProvider theme={theme}>{children}</ChakraProvider>;
}
