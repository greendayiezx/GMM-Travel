/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,ts}"],
  // Preflight dimatikan supaya reset Tailwind tidak menimpa CSS desktop
  // yang sudah ada. Layar mobile memakai kelas Tailwind eksplisit.
  corePlugins: { preflight: false },
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        // Brand (selaras dengan website)
        "azure-sky": "#1E9BF0",
        "solar-flare": "#FFD600",
        "electric-lime": "#AAEE00",
        "deep-onyx": "#1A1A1A",
        // Material Design 3 (dari design Stitch)
        primary: "#00629d",
        "on-primary": "#ffffff",
        "primary-container": "#1e9bf0",
        "on-primary-container": "#003050",
        secondary: "#486800",
        "secondary-container": "#b0f413",
        "on-secondary-container": "#4c6c00",
        tertiary: "#705d00",
        "tertiary-container": "#caa900",
        error: "#ba1a1a",
        "error-container": "#ffdad6",
        "on-error-container": "#93000a",
        background: "#fcf9f8",
        "on-background": "#1c1b1b",
        surface: "#fcf9f8",
        "surface-alt": "#F8FAFC",
        "surface-variant": "#e5e2e1",
        "surface-container-lowest": "#ffffff",
        "surface-container-low": "#f6f3f2",
        "surface-container": "#f0eded",
        "surface-container-high": "#eae7e7",
        "surface-container-highest": "#e5e2e1",
        "surface-dim": "#dcd9d9",
        "on-surface": "#1c1b1b",
        "on-surface-variant": "#3f4851",
        outline: "#6f7883",
        "outline-variant": "#bfc7d3",
        "inverse-surface": "#313030",
        "inverse-on-surface": "#f3f0ef",
      },
      borderRadius: {
        DEFAULT: "0.25rem",
        lg: "0.5rem",
        xl: "0.75rem",
        full: "9999px",
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
        display: ["Outfit", "system-ui", "sans-serif"],
      },
    },
  },
  plugins: [],
};
