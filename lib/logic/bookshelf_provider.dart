import 'package:meta/meta.dart' show required;
import 'package:quiver/core.dart' show Optional;

import 'native.dart' show getString, setString;
import 'provider.dart' show Provider;

final _BookshelfProvider bookshelfProvider = _BookshelfProvider();

enum BookshelfRequestHead {
  Get,
  Add,
  Remove,
}

class BookCover {
  const BookCover({
    @required this.bookUrl,
    @required this.bookTitle,
    @required this.bookImageUrl,
  });

  final String bookUrl;
  final String bookTitle;
  final String bookImageUrl;
}

class BookshelfRequest {
  const BookshelfRequest({
    @required this.head,
    @required this.body,
  });

  final BookshelfRequestHead head;
  final BookCover body;
}

class Bookshelf {
  const Bookshelf._({
    @required this.bookCoverList,
  });

  final List<BookCover> bookCoverList;
}

class _BookshelfProvider extends Provider<BookshelfRequest, Bookshelf> {
  @override
  void request(BookshelfRequest request) {
    if (value != null && request.head == BookshelfRequestHead.Get) {
      super.request(request);
      return;
    }

    switch (request.head) {
      case BookshelfRequestHead.Get:
        _getBookshelf().then((bookshelf) {
          value = bookshelf;
          super.request(request);
        });
        break;

      case BookshelfRequestHead.Add:
        _addBook(
          bookUrl: request.body.bookUrl,
          bookTitle: request.body.bookTitle,
          bookImageUrl: request.body.bookImageUrl,
        ).then((bookshelf) {
          value = bookshelf;
          super.request(request);
        });
        break;

      case BookshelfRequestHead.Remove:
        _removeBook(
          bookUrl: request.body.bookUrl,
        ).then((bookshelf) {
          value = bookshelf;
          super.request(request);
        });
        break;

      default:
    }
  }
}

Future<Bookshelf> _getBookshelf() async {
  final Optional<String> rawString = await getString('book_list');
  final List<BookCover> bookCoverList = <BookCover>[];

  if (rawString.isNotPresent) {
    return Bookshelf._(bookCoverList: bookCoverList);
  }

  final List<String> rawBookCoverList = rawString.value.split('\n')
    ..removeLast();

  for (final String rawBookCover in rawBookCoverList) {
    final List<String> bookCover = rawBookCover.split('_');

    bookCoverList.add(
      BookCover(
        bookUrl: bookCover[0],
        bookTitle: bookCover[1],
        bookImageUrl: bookCover[2],
      ),
    );
  }

  return Bookshelf._(bookCoverList: bookCoverList);
}

Future<bool> _setBookshelf(Bookshelf bookshelf) async {
  final StringBuffer buffer = StringBuffer();
  for (final BookCover bookCover in bookshelf.bookCoverList) {
    buffer
      ..write(bookCover.bookUrl)
      ..write('_')
      ..write(bookCover.bookTitle)
      ..write('_')
      ..write(bookCover.bookImageUrl)
      ..write('\n');
  }
  return await setString(
    'book_list',
    buffer.toString(),
  );
}

Future<Bookshelf> _addBook({
  @required String bookUrl,
  @required String bookTitle,
  @required String bookImageUrl,
}) async {
  final Bookshelf bookshelf = await _getBookshelf();

  // 如果已经有了，直接返回 true
  if (bookshelf.bookCoverList
      .any((bookCover) => bookCover.bookUrl == bookUrl)) {
    return bookshelf;
  }

  bookshelf.bookCoverList.add(
    BookCover(
      bookUrl: bookUrl,
      bookTitle: bookTitle,
      bookImageUrl: bookImageUrl,
    ),
  );

  await _setBookshelf(bookshelf);

  return bookshelf;
}

Future<Bookshelf> _removeBook({@required String bookUrl}) async {
  final Bookshelf bookshelf = await _getBookshelf();

  if (bookshelf.bookCoverList.isEmpty) {
    return bookshelf;
  }

  bookshelf.bookCoverList
      .removeWhere((bookCover) => bookCover.bookUrl == bookUrl);

  await _setBookshelf(bookshelf);

  return bookshelf;
}
