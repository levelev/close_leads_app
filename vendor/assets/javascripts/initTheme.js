const body = document.body;
const theme = localStorage.getItem('theme')

if (theme) {
  console.log("initializing theme")
  document.documentElement.setAttribute('data-bs-theme', theme)
}
