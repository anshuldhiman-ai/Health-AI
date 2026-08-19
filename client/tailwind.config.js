/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: {
        // Functional green/red — used only for gains/losses per CLAUDE.md.
        gain: "#16a34a",
        loss: "#dc2626",
      },
    },
  },
  plugins: [],
};
