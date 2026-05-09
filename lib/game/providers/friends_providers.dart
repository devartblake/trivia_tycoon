import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/social/friend_list_item_dto.dart';
import '../../core/models/social/friend_request_dto.dart';
import '../../core/models/social/friend_suggestion_dto.dart';
import '../../core/models/social/paginated_social_response.dart';
import 'profile_providers.dart';

final friendsListProvider =
    FutureProvider<PaginatedSocialResponse<FriendListItemDto>>((ref) async {
  final service = ref.watch(backendProfileSocialServiceProvider);
  return service.getFriends();
});

final incomingFriendRequestsProvider =
    FutureProvider<PaginatedSocialResponse<FriendRequestDto>>((ref) async {
  final service = ref.watch(backendProfileSocialServiceProvider);
  return service.getIncomingFriendRequests();
});

final sentFriendRequestsProvider =
    FutureProvider<PaginatedSocialResponse<FriendRequestDto>>((ref) async {
  final service = ref.watch(backendProfileSocialServiceProvider);
  return service.getSentFriendRequests();
});

final friendSuggestionsProvider =
    FutureProvider<List<FriendSuggestionDto>>((ref) async {
  final service = ref.watch(backendProfileSocialServiceProvider);
  return service.getFriendSuggestions();
});

/// Reactive stream that re-emits the friends list whenever
/// [friendsListProvider] is invalidated (e.g. after a mutation).
final friendsListStreamProvider = StreamProvider<List<FriendListItemDto>>((ref) async* {
  yield (await ref.watch(friendsListProvider.future)).items;
});

/// Reactive stream that re-emits pending requests whenever
/// [incomingFriendRequestsProvider] is invalidated.
final pendingRequestsStreamProvider = StreamProvider<List<FriendRequestDto>>((ref) async* {
  yield (await ref.watch(incomingFriendRequestsProvider.future)).items;
});

final blockedUsersProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(backendProfileSocialServiceProvider).getBlockedUserIds();
});

final favouriteFriendIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(backendProfileSocialServiceProvider).getFavouriteFriendIds();
});
