import 'package:meta/meta.dart' show required;
import 'package:quiver/iterables.dart' show range;

import 'network.dart' show getResponseBody;
import 'provider.dart' show Provider;

final _SearchProvider searchProvider = _SearchProvider();

class SearchRequest {
  const SearchRequest({
    @required this.body,
  });

  final String body;
}

class Search {
  const Search._({
    @required this.searchUrl,
    @required this.bookDetailUrlList,
    @required this.bookTitleList,
    @required this.bookAuthorList1,
    @required this.bookAuthorList2,
  });

  final String searchUrl;
  final List<String> bookDetailUrlList;
  final List<String> bookTitleList;
  final List<String> bookAuthorList1;
  final List<String> bookAuthorList2;
}

class _SearchProvider extends Provider<SearchRequest, Search> {
  @override
  void request(SearchRequest request) {
    if (value != null && request.body == value.searchUrl) {
      super.request(request);
      return;
    }

    _search(request.body).then((search) {
      value = search;
      super.request(request);
    });
  }
}

Future<Search> _search(String searchUrl) async {
  final RegExp responseBodyRegExp =
      RegExp('<div class="recommend mybook">(.*?)<form class="searchForm"');
  final RegExp lengthRegExp = RegExp('value="([0-9]*)/([0-9]*)"');
  final RegExp bookDetailUrlRegExp = RegExp('<a href="https://(.*?)">');
  final RegExp bookTitleRegExp = RegExp('<p class="title">(.*?)</p>');
  final RegExp bookAuthorRegExp = RegExp('<p class="author">(.*?)</p>');

  String responseBody =
      responseBodyRegExp.firstMatch(await getResponseBody(searchUrl)).group(1);

  final List<String> bookDetailUrlList = [];
  final List<String> bookTitleList = [];
  final List<String> bookAuthorList1 = [];
  final List<String> bookAuthorList2 = [];

  final int length = lengthRegExp.hasMatch(responseBody)
      ? int.parse(lengthRegExp.firstMatch(responseBody).group(2))
      : 1;

  for (final int index in range(1, length + 1)) {
    responseBody = (index == 1)
        ? responseBody
        : responseBodyRegExp
            .firstMatch(await getResponseBody('$searchUrl&page=$index'))
            .group(1);

    final Iterable<Match> bookDetailUrlMatches =
        bookDetailUrlRegExp.allMatches(responseBody);
    final Iterable<Match> bookTitleMatches =
        bookTitleRegExp.allMatches(responseBody);
    final Iterable<Match> bookAuthorMatches =
        bookAuthorRegExp.allMatches(responseBody);

    for (final int index in range(0, bookDetailUrlMatches.length)) {
      final String bookDetailUrl =
          bookDetailUrlMatches.elementAt(index).group(1).trimLeft().trimRight();
      final String bookTitle =
          bookTitleMatches.elementAt(index).group(1).trimLeft().trimRight();
      final String bookAuthor1 = bookAuthorMatches
          .elementAt(index * 2)
          .group(1)
          .trimLeft()
          .trimRight();
      final String bookAuthor2 = bookAuthorMatches
          .elementAt(index * 2 + 1)
          .group(1)
          .trimLeft()
          .trimRight();

      bookDetailUrlList.add('https://$bookDetailUrl');
      bookTitleList.add(bookTitle);
      bookAuthorList1.add(bookAuthor1);
      bookAuthorList2.add(bookAuthor2);
    }
  }

  return Search._(
    searchUrl: searchUrl,
    bookDetailUrlList: bookDetailUrlList,
    bookTitleList: bookTitleList,
    bookAuthorList1: bookAuthorList1,
    bookAuthorList2: bookAuthorList2,
  );
}
