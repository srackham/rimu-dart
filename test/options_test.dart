import 'package:test/test.dart';
import 'package:rimu/src/options.dart';

void main() {
  test('init', () {
    init();
    expect(safeMode, 0);
    expect(htmlReplacement, '<mark>replaced HTML</mark>');
    expect(callback, null);
  });
  test('isSafeModeNz', () {
    init();
    expect(isSafeModeNz(), false);
    safeMode=1;
    expect(isSafeModeNz(), true);
  });
}

/*
func TestIsSafeModeNz(t *testing.T) {
	Init()
	assert.False(t, IsSafeModeNz())
	safeMode = 1
	assert.True(t, IsSafeModeNz())
}

func TestSkipMacroDefs(t *testing.T) {
	Init()
	assert.False(t, SkipMacroDefs())
	safeMode = 1
	assert.True(t, SkipMacroDefs())
	safeMode = 1 + 8
	assert.False(t, SkipMacroDefs())
}

func TestSkipBlockAttributes(t *testing.T) {
	Init()
	assert.False(t, SkipBlockAttributes())
	safeMode = 1
	assert.False(t, SkipBlockAttributes())
	safeMode = 1 + 4
	assert.True(t, SkipBlockAttributes())
}

func TestUpdateOptions(t *testing.T) {
	Init()
	UpdateOptions(RenderOptions{SafeMode: 1})
	assert.Equal(t, 1, safeMode)
	assert.Equal(t, "<mark>replaced HTML</mark>", htmlReplacement)
	UpdateOptions(RenderOptions{HtmlReplacement: "foo"})
	assert.Equal(t, 1, safeMode)
	assert.Equal(t, "foo", htmlReplacement)
}

func TestSetOption(t *testing.T) {
	Init()
	// Illegal values do not update options.
	SetOption("safeMode", "qux")
	assert.Equal(t, 0, safeMode)
	SetOption("safeMode", "42")
	assert.Equal(t, 0, safeMode)
	SetOption("safeMode", "1")
	SetOption("reset", "qux")
	assert.Equal(t, 1, safeMode)
}

func TestHtmlSafeModeFilter(t *testing.T) {
	Init()
	assert.Equal(t, "foo", HtmlSafeModeFilter("foo"))
	safeMode = 1
	assert.Equal(t, "", HtmlSafeModeFilter("foo"))
	safeMode = 2
	assert.Equal(t, "<mark>replaced HTML</mark>", HtmlSafeModeFilter("foo"))
	safeMode = 3
	assert.Equal(t, "&lt;br&gt;", HtmlSafeModeFilter("<br>"))
	safeMode = 0 + 4
	assert.Equal(t, "foo", HtmlSafeModeFilter("foo"))
}
*/