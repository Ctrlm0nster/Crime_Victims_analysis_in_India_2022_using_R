// Blob downloads work with both a native Shiny server and browser-only ShinyLive.
$(document).on("shiny:connected", function () {
  Shiny.addCustomMessageHandler("download-csv", function (message) {
    const blob = new Blob(["\uFEFF", message.csv], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = message.filename;
    document.body.appendChild(link);
    link.click();
    link.remove();
    setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
  });
});
