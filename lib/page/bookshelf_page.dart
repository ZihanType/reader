import 'package:flutter/material.dart';

import '../logic/bookshelf_provider.dart'
    show
        bookshelfProvider,
        Bookshelf,
        BookshelfRequest,
        BookshelfRequestHead,
        BookCover;
import 'widget/book_cover_widget.dart' show BookCoverWidget;

class BookshelfPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: bookshelfProvider.response,
      builder: (context, snapshot) {
        final Bookshelf bookshelf = snapshot.data as Bookshelf;

        if (bookshelf == null || bookshelf.bookCoverList == null) {
          bookshelfProvider.request(
            BookshelfRequest(
              head: BookshelfRequestHead.Get,
              body: BookCover(
                bookUrl: null,
                bookTitle: null,
                bookImageUrl: null,
              ),
            ),
          );
          return Container();
        }

        return Scrollbar(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
            ),
            itemCount: bookshelf.bookCoverList.length,
            itemBuilder: (context, index) {
              return Container(
                padding: EdgeInsets.all(10.0),
                child: BookCoverWidget(
                  bookTitle: bookshelf.bookCoverList[index].bookTitle,
                  bookImageUrl: bookshelf.bookCoverList[index].bookImageUrl,
                  bookUrl: bookshelf.bookCoverList[index].bookUrl,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
