import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImage;
import 'package:flutter/material.dart';

import '../../logic/bookshelf_provider.dart'
    show bookshelfProvider, BookshelfRequest, BookshelfRequestHead, BookCover;
import '../../page/read_page.dart' show ReadPage;

class BookCoverWidget extends StatelessWidget {
  const BookCoverWidget({
    @required this.bookUrl,
    @required this.bookTitle,
    @required this.bookImageUrl,
  });

  final String bookUrl;
  final String bookTitle;
  final String bookImageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return ReadPage(
                bookUrl: bookUrl,
                bookTitle: bookTitle,
                readingChapterTitle: null,
              );
            },
          ),
        );
      },
      onLongPress: () {
        bookshelfProvider.request(
          BookshelfRequest(
            head: BookshelfRequestHead.Remove,
            body: BookCover(
              bookUrl: bookUrl,
              bookTitle: null,
              bookImageUrl: null,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: CachedNetworkImage(
              imageUrl: bookImageUrl,
              fit: BoxFit.fill,
            ),
          ),
          Text(
            bookTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
