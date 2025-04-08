// PASTE ME into Console in devtools
javascript:(() => {
  // Gather all <script> elements into an array
  const scriptElements = Array.from(document.querySelectorAll('script'));
  // Define a regular expression to match HTTP/HTTPS URLs
  const urlPattern = /\bhttps?:\/\/[^\s"']+/g;
  // Use a Set to store unique URLs found on the page
  const foundUrls = new Set();

  // Process each script element to add its "src" value if it matches the URL pattern
  scriptElements.forEach(element => {
    const srcValue = element.src;
    if (srcValue && urlPattern.test(srcValue)) {
      foundUrls.add(srcValue);
    }
  });

  // Fetch the entire page's HTML source
  fetch(window.location.href)
    .then(response => response.text())
    .then(htmlSource => {
      // Extract URLs from the fetched HTML source text
      for (const match of htmlSource.matchAll(urlPattern)) {
        foundUrls.add(match[0]);
      }

      // Additionally, scan the document's HTML content as a safety net
      for (const match of document.documentElement.outerHTML.matchAll(urlPattern)) {
        foundUrls.add(match[0]);
      }

      // Replace the current document content with the list of URLs
      document.open();
      document.write('<html><head><title>Extracted URLs</title></head><body>');
      foundUrls.forEach(url => {
        document.write(url + '<br>');
      });
      document.write('</body></html>');
      document.close();
    })
    .catch(error => console.error('An error occurred while fetching the page:', error));

  // Stop the page from continuing to load after 3 seconds to prevent interference
  setTimeout(() => {
    window.stop();
  }, 3000);
})();
