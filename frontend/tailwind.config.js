/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: "var(--ink)",
        "ink-2": "var(--ink-2)",
        rule: "var(--rule)",
        vellum: "var(--vellum)",
        "vellum-dim": "var(--vellum-dim)",
        amber: "var(--amber)",
        vermilion: "var(--vermilion)",
        jade: "var(--jade)",
        lilac: "var(--lilac)",
        sky: "var(--sky)",
        magenta: "var(--magenta)",
      },
      fontFamily: {
        display: ["Fraunces", "serif"],
        reading: ["Literata", "serif"],
        mono: ["IBM Plex Mono", "monospace"],
      },
    },
  },
  plugins: [],
};
