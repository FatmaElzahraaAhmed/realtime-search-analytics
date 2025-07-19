const searchBox = document.getElementById("search-box");
let timeout = null;

function sendQuery(term, finalize = false) {
  fetch("/search_queries/record", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "term=" + encodeURIComponent(term) + "&finalize=" + finalize,
  });
}

if (searchBox) {
  searchBox.addEventListener("input", function () {
    clearTimeout(timeout);

    const term = searchBox.value.trim();
    if (term === "") return;

    sendQuery(term, false);

    timeout = setTimeout(() => {
      sendQuery(term, true);
    }, 2000);
  });
}
