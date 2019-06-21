import 'package:meta/meta.dart' show required;
import 'package:quiver/core.dart' show Optional;
import 'package:quiver/iterables.dart' show range;

import '../constants.dart' show host;
import 'native.dart' show getString, setString;
import 'network.dart' show getResponseBody;
import 'provider.dart' show Provider;

final _BookProvider bookProvider = _BookProvider();

class BookRequest {
  const BookRequest({
    @required this.bookUrl,
    @required this.bookTitle,
    @required this.readingChapterTitle,
  });

  final String bookUrl;
  final String bookTitle;
  final String readingChapterTitle;
}

class Book {
  Book._({
    @required this.bookUrl,
    @required this.bookTitle,
    @required this.readingChapterTitle,
    @required this.readingChapterContent,
    @required this.chapterTitleList,
    @required this.chapterTitleToChapterUrlMap,
  });

  final String bookUrl;
  final String bookTitle;
  String readingChapterTitle;
  String readingChapterContent;
  final List<String> chapterTitleList;
  final Map<String, String> chapterTitleToChapterUrlMap;

  void toNamedChapter(String chapterTitle) {
    if (chapterTitle == null) {
      return;
    }

    readingChapterTitle = chapterTitle;

    _setReadingChapterTitle(
      bookUrl,
      readingChapterTitle,
    ).then((_) {
      _getChapterContent(
        bookUrl,
        readingChapterTitle,
        chapterTitleToChapterUrlMap[readingChapterTitle],
      ).then((chapterContent) {
        readingChapterContent = chapterContent;
        bookProvider.request(
          BookRequest(
            bookUrl: bookUrl,
            bookTitle: bookTitle,
            readingChapterTitle: readingChapterTitle,
          ),
        );
        _downloadChapterContent(
          bookUrl,
          readingChapterTitle,
          chapterTitleList,
          chapterTitleToChapterUrlMap,
        );
      });
    });
  }

  void toPrevChapter() {
    final int index = chapterTitleList.indexOf(readingChapterTitle);
    if (index > 0) {
      toNamedChapter(chapterTitleList[index - 1]);
    }
  }

  void toNextChapter() {
    final int index = chapterTitleList.indexOf(readingChapterTitle);
    if (index < chapterTitleList.length - 1) {
      toNamedChapter(chapterTitleList[index + 1]);
    }
  }
}

class _BookProvider extends Provider<BookRequest, Book> {
  @override
  void request(BookRequest request) {
    if (value != null) {
      if (request.readingChapterTitle != null &&
          request.readingChapterTitle != value.readingChapterTitle) {
        value.toNamedChapter(request.readingChapterTitle);
        return;
      }

      if (request.bookUrl == value.bookUrl) {
        super.request(request);
        return;
      }
    }

    _init(request).then((book) {
      value = book;
      super.request(request);
      _downloadChapterContent(
        value.bookUrl,
        value.readingChapterTitle,
        value.chapterTitleList,
        value.chapterTitleToChapterUrlMap,
      );
    });
  }
}

/// ----------------------------------------------------------------------------
/// 处理正读章节标题

Future<Optional<String>> _getReadingChapterTitle(String bookUrl) async {
  return await getString(
    '${bookUrl}_reading_chapter_title',
  );
}

Future<bool> _setReadingChapterTitle(
  String bookUrl,
  String readingChapterTitle,
) async {
  return await setString(
    '${bookUrl}_reading_chapter_title',
    readingChapterTitle,
  );
}

/// 处理正读章节标题
/// ----------------------------------------------------------------------------

/// ----------------------------------------------------------------------------
/// 处理哈希表

Future<Optional<Map<String, String>>> _getChapterTitleToChapterUrlMap(
  String bookUrl,
) async {
  final Optional<String> rawString = await getString(
    '${bookUrl}_chapter_title_to_chapter_url_map',
  );

  if (rawString.isNotPresent) {
    return Optional.absent();
  }

  final Map<String, String> titleToUrlMap = <String, String>{};
  final List<String> titleAndUrlList = rawString.value.split('^^^')
    ..removeLast();

  for (final String titleAndUrl in titleAndUrlList) {
    final String title = titleAndUrl.split('___')[0];
    final String url = titleAndUrl.split('___')[1];
    titleToUrlMap[title] = url;
  }

  return Optional.of(titleToUrlMap);
}

Future<bool> _setChapterTitleToChapterUrlMap(
  String bookUrl,
  Map<String, String> chapterTitleToChapterUrlMap,
) async {
  final StringBuffer buffer = StringBuffer();

  chapterTitleToChapterUrlMap.forEach((chapterTitle, chapterUrl) {
    buffer.write('${chapterTitle}___$chapterUrl^^^');
  });

  return await setString(
    '${bookUrl}_chapter_title_to_chapter_url_map',
    buffer.toString(),
  );
}

/// 处理哈希表
/// ----------------------------------------------------------------------------

/// ----------------------------------------------------------------------------
/// 处理章节标题列表

Future<Optional<List<String>>> _getChapterTitleList(
  String bookUrl,
) async {
  final Optional<String> rawString = await getString(
    '${bookUrl}_chapter_title_list',
  );

  if (rawString.isNotPresent) {
    return Optional.absent();
  }

  return Optional.of(rawString.value.split('___')..removeLast());
}

Future<bool> _setChapterTitleList(
  String bookUrl,
  List<String> chapterTitleList,
) async {
  final StringBuffer buffer = StringBuffer();

  for (final String chapterTitle in chapterTitleList) {
    buffer.write('${chapterTitle}___');
  }

  return await setString(
    '${bookUrl}_chapter_title_list',
    buffer.toString(),
  );
}

/// 处理章节标题列表
/// ----------------------------------------------------------------------------

/// ----------------------------------------------------------------------------
/// 处理章节内容
Future<String> _getChapterContent(
  String bookUrl,
  String chapterTitle,
  String chapterUrl,
) async {
  final Optional<String> chapterContentFromNative =
      await _getChapterContentFromNative(bookUrl, chapterTitle);

  if (chapterContentFromNative.isPresent &&
      chapterContentFromNative.value.split('\n\n')[0] == chapterTitle) {
    return chapterContentFromNative.value;
  }

  return await _getChapterContentFromNetwork(
    bookUrl,
    chapterTitle,
    chapterUrl,
  );
}

Future<String> _getChapterContentFromNetwork(
  String bookUrl,
  String chapterTitle,
  String chapterUrl,
) async {
  String responseBody = await getResponseBody(chapterUrl);
  final StringBuffer buffer = StringBuffer()..write('$chapterTitle\n\n');

  final RegExp chapterContentRegExp =
      RegExp(r'''</p>.*</p>(.*?)<br />(.*)</br>''');
  final RegExp spanRegExp = RegExp('<span(.*?)</span>');
  final RegExp lengthRegExp = RegExp('第([0-9]*)/([0-9]*)页');

  final int length = lengthRegExp.hasMatch(responseBody)
      ? int.parse(lengthRegExp.firstMatch(responseBody).group(2))
      : 1;
  for (final int index in range(1, length + 1)) {
    responseBody = (index == 1)
        ? responseBody
        : await getResponseBody(
            chapterUrl.replaceFirst('.html', '_$index.html'),
          );

    if (!chapterContentRegExp.hasMatch(responseBody)) {
      return '正在手打中，客官请稍等片刻，内容更新后，需要重新刷新页面，才能获取最新更新！';
    }

    final Match match = chapterContentRegExp.firstMatch(responseBody);
    buffer..write(match.group(1))..write('<br />')..write(match.group(2));
  }

  String chapterContent = buffer
      .toString()
      .replaceAll('<br />', '\n')
      .replaceAll('&nbsp;', '')
      .replaceAll('</br>', '');

  final String span = spanRegExp.hasMatch(chapterContent)
      ? '<span${spanRegExp.firstMatch(chapterContent).group(1)}</span>'
      : '';

  chapterContent = chapterContent.replaceAll(span, '');

  await _setChapterContent(bookUrl, chapterTitle, chapterContent);

  return chapterContent;
}

Future<Optional<String>> _getChapterContentFromNative(
  String bookUrl,
  String chapterTitle,
) async {
  return await getString(
    '${bookUrl}_${chapterTitle}_chapter_content',
  );
}

Future<bool> _setChapterContent(
  String bookUrl,
  String chapterTitle,
  String chapterContent,
) async {
  return await setString(
    '${bookUrl}_${chapterTitle}_chapter_content',
    chapterContent,
  );
}

/// 处理章节内容
/// ----------------------------------------------------------------------------

Future<Book> _init(BookRequest request) async {
  final Optional<String> readingChapterTitleFromNative =
      await _getReadingChapterTitle(request.bookUrl);
  final Optional<List<String>> chapterTitleListFromNative =
      await _getChapterTitleList(request.bookUrl);
  final Optional<Map<String, String>> chapterTitleToChapterUrlMapFromNative =
      await _getChapterTitleToChapterUrlMap(request.bookUrl);

  if (chapterTitleListFromNative.isPresent &&
      chapterTitleToChapterUrlMapFromNative.isPresent) {
    final String readingChapterTitle = request.readingChapterTitle ??
        (readingChapterTitleFromNative.orNull ??
            chapterTitleListFromNative.value[0]);

    await _setReadingChapterTitle(request.bookUrl, readingChapterTitle);

    final String readingChapterContent = await _getChapterContent(
      request.bookUrl,
      readingChapterTitle,
      chapterTitleToChapterUrlMapFromNative.value[readingChapterTitle],
    );

    return Book._(
      bookUrl: request.bookUrl,
      bookTitle: request.bookTitle,
      readingChapterTitle: readingChapterTitle,
      readingChapterContent: readingChapterContent,
      chapterTitleList: chapterTitleListFromNative.value,
      chapterTitleToChapterUrlMap: chapterTitleToChapterUrlMapFromNative.value,
    );
  }

  final List<String> chapterTitleList = <String>[];
  final Map<String, String> chapterTitleToChapterUrlMap = <String, String>{};

  final String responseBody = await getResponseBody(request.bookUrl);

  final RegExp titleAndUrlRegExp = RegExp('<p>(.*?)</p>');
  final RegExp titleRegExp = RegExp('<a style=".*?" href=".*?">(.*?)</a>');
  final RegExp urlRegExp = RegExp('<a style=".*?" href="/(.*?)">');
  final Iterable<Match> matches = titleAndUrlRegExp.allMatches(responseBody);

  for (final Match match in matches) {
    final String titleAndUrl = match.group(1);

    if (titleRegExp.hasMatch(titleAndUrl) && urlRegExp.hasMatch(titleAndUrl)) {
      final String title = titleRegExp.firstMatch(titleAndUrl).group(1);
      final String url = '$host${urlRegExp.firstMatch(titleAndUrl).group(1)}';
      chapterTitleList.add(title);
      chapterTitleToChapterUrlMap[title] = url;
    }
  }

  final String readingChapterTitle = request.readingChapterTitle ??
      (readingChapterTitleFromNative.orNull ?? chapterTitleList[0]);

  await _setReadingChapterTitle(request.bookUrl, readingChapterTitle);

  final String readingChapterContent = await _getChapterContent(
    request.bookUrl,
    readingChapterTitle,
    chapterTitleToChapterUrlMap[readingChapterTitle],
  );

  await _setChapterTitleList(
    request.bookUrl,
    chapterTitleList,
  );
  await _setChapterTitleToChapterUrlMap(
    request.bookUrl,
    chapterTitleToChapterUrlMap,
  );

  return Book._(
    bookUrl: request.bookUrl,
    bookTitle: request.bookTitle,
    readingChapterTitle: readingChapterTitle,
    readingChapterContent: readingChapterContent,
    chapterTitleList: chapterTitleList,
    chapterTitleToChapterUrlMap: chapterTitleToChapterUrlMap,
  );
}

/// 下载其他章节内容
Future<void> _downloadChapterContent(
  String bookUrl,
  String readingChapterTitle,
  List<String> chapterTitleList,
  Map<String, String> chapterTitleToChapterUrlMap,
) async {
  final int length = chapterTitleList.length;
  final int readingIndex = chapterTitleList.indexOf(readingChapterTitle);
  final int start = readingIndex - 3;
  final int end = readingIndex + 3;

  for (final int index in range(start, end + 1)) {
    if (0 <= index && index != readingIndex && index < length) {
      final String chapterTitle = chapterTitleList[index];
      await _getChapterContent(
        bookUrl,
        chapterTitle,
        chapterTitleToChapterUrlMap[chapterTitle],
      );
    }
  }
}
