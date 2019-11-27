String replaceSpecialChars(String s) {
  return s
      .replaceAll('&', '&amp;')
      .replaceAll('>', '&gt;')
      .replaceAll('<', '&lt;');
}
