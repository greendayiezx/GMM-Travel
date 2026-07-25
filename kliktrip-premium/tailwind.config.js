/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{html,ts}",
  ],
  theme: {
    extend: {
      colors: {
        primary: '#1E9BF0',
        accent: '#AAEE00',
        dark: '#1A1A1A',
        'dark-2': '#2C3E50',
        light: '#F8F9FA',
      },
    },
  },
  plugins: [],
}

