import 'package:bookshelf/core/validators.dart';
import 'package:bookshelf/services/book_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authentication validation', () {
    test('email messages match the specification', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('invalid'), 'Please enter a valid email address');
      expect(Validators.email('reader@example.com'), isNull);
    });

    test('register password messages match the specification', () {
      expect(Validators.password('', enforceLength: true), 'Password is required');
      expect(Validators.password('12345', enforceLength: true), 'Password must be at least 6 characters');
      expect(Validators.confirmPassword('', '123456'), 'Confirm password is required');
      expect(Validators.confirmPassword('654321', '123456'), 'Passwords do not match');
    });
  });

  group('book validation boundaries', () {
    test('required text rejects spaces and accepts maximum length', () {
      expect(Validators.title('   '), 'Title is required');
      expect(Validators.title('a' * 100), isNull);
      expect(Validators.title('a' * 101), 'Title must be at most 100 characters');
      expect(Validators.author('a' * 60), isNull);
      expect(Validators.author('a' * 61), 'Author must be at most 60 characters');
    });

    test('rating accepts only optional whole numbers from zero to five', () {
      expect(Validators.rating(''), isNull);
      expect(Validators.rating('0'), isNull);
      expect(Validators.rating('5'), isNull);
      expect(Validators.rating('-1'), 'Rating must be a whole number from 0 to 5');
      expect(Validators.rating('2.5'), 'Rating must be a whole number from 0 to 5');
      expect(Validators.rating('6'), 'Rating must be a whole number from 0 to 5');
    });

    test('notes enforce the 300 character boundary', () {
      expect(Validators.notes('a' * 300), isNull);
      expect(Validators.notes('a' * 301), 'Notes must be at most 300 characters');
    });
  });

  test('book id is stable across case and surrounding spaces', () {
    final first = BookService.idFor('uid', ' Dune ', 'Frank Herbert');
    final second = BookService.idFor('uid', 'dune', ' frank herbert ');
    expect(first, second);
    expect(first, startsWith('uid__'));
  });
}
