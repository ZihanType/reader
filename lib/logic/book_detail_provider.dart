import 'package:meta/meta.dart' show required;

import '../constants.dart' show host;
import 'network.dart' show getResponseBody;
import 'provider.dart' show Provider;

final _BookDetailProvider bookDetailProvider = _BookDetailProvider();

class BookDetailRequest {
  const BookDetailRequest({
    @required this.bookDetailUrl,
    @required this.bookTitle,
    @required this.bookAuthor1,
    @required this.bookAuthor2,
  });

  final String bookDetailUrl;
  final String bookTitle;
  final String bookAuthor1;
  final String bookAuthor2;
}

class BookDetail {
  const BookDetail._({
    @required this.bookUrl,
    @required this.bookTitle,
    @required this.bookImageUrl,
    @required this.bookDetailUrl,
    @required this.bookCategory,
    @required this.bookAuthor,
    @required this.bookUpdateState,
    @required this.bookNewestChapterTitle,
    @required this.bookNewestUpdateTime,
    @required this.bookDescription,
    @required this.detailChapterTitleList,
  });

  final String bookUrl;
  final String bookTitle;
  final String bookImageUrl;
  final String bookDetailUrl;
  final String bookCategory;
  final String bookAuthor;
  final String bookUpdateState;
  final String bookNewestChapterTitle;
  final String bookNewestUpdateTime;
  final String bookDescription;
  final List<String> detailChapterTitleList;
}

class _BookDetailProvider extends Provider<BookDetailRequest, BookDetail> {
  @override
  void request(BookDetailRequest request) {
    if (value != null && request.bookDetailUrl == value.bookDetailUrl) {
      super.request(request);
      return;
    }

    _init(request).then((bookDetail) {
      value = bookDetail;
      super.request(request);
    });
  }
}

Future<BookDetail> _init(BookDetailRequest request) async {
  final String responseBody = await getResponseBody(request.bookDetailUrl);

  final RegExp bookImageUrlRegExp = RegExp('<img src="(.*?)"');
  final RegExp bookNewestUpdateTimeRegExp = RegExp('<p class="">更新：(.*?)</p>');
  final RegExp bookDescriptionRegExp =
      RegExp('<meta property="og:description" content="(.*?)" />');
  final RegExp bookUrlRegExp =
      RegExp('<a id="AllChapterList" href="/(.*?)">开始阅读</a>');

  final String bookImageUrl =
      bookImageUrlRegExp.firstMatch(responseBody).group(1);
  final String bookNewestUpdateTime =
      '更新：${bookNewestUpdateTimeRegExp.firstMatch(responseBody).group(1)}';
  final String bookDescription = bookDescriptionRegExp
      .firstMatch(responseBody)
      .group(1)
      .replaceAll('<br/>', '\n');
  final String bookUrl =
      '$host${bookUrlRegExp.firstMatch(responseBody).group(1)}';

  final RegExp detailChapterTitleListRegExp =
      RegExp('<div id="chapterlist" class="directoryArea">(.*?)</div>');
  final RegExp detailChapterTitleRegExp = RegExp('<a.*?>(.*?)</a>');

  final Iterable<Match> detailChapterTitleMatches =
      detailChapterTitleRegExp.allMatches(
    detailChapterTitleListRegExp.firstMatch(responseBody).group(1),
  );

  final List<String> detailChapterTitleList = <String>[];

  for (final Match match in detailChapterTitleMatches) {
    detailChapterTitleList.add(
      match.group(1).trimLeft().trimRight(),
    );
  }

  final String bookNewestChapterTitle = '最新：${detailChapterTitleList.last}';
  final String bookCategory =
      request.bookAuthor1.split('|')[0].trimLeft().trimRight();
  final String bookAuthor =
      request.bookAuthor1.split('|')[1].trimLeft().trimRight();
  final String bookUpdateState =
      request.bookAuthor2.split('|')[0].trimLeft().trimRight();

  return BookDetail._(
    bookUrl: bookUrl,
    bookTitle: request.bookTitle,
    bookImageUrl: bookImageUrl,
    bookDetailUrl: request.bookDetailUrl,
    bookCategory: bookCategory,
    bookAuthor: bookAuthor,
    bookUpdateState: bookUpdateState,
    bookNewestChapterTitle: bookNewestChapterTitle,
    bookNewestUpdateTime: bookNewestUpdateTime,
    bookDescription: bookDescription,
    detailChapterTitleList: detailChapterTitleList,
  );
}
