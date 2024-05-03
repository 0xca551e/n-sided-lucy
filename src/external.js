export function requestAnimationFrame(callback) {
  return window.requestAnimationFrame(callback);
}

export function downloadSvg(selector) {
  var svg = document.querySelector(selector);
  var svgSource = svg.outerHTML;
  var svgDataUri = "data:image/svg+xml;base64," + btoa(svgSource);
  const link = document.createElement("a");
  link.href = svgDataUri;
  link.download = "download";
  link.click();
}
