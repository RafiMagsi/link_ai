class FeedPostUiModel {
  final String id;
  final String authorName;
  final String authorRole;
  final String? authorAvatarUrl;
  final String timestampText;
  final String text;
  final List<String> mediaUrls;
  final int likesCount;
  final int repostsCount;
  final int commentsCount;
  final int savesCount;

  const FeedPostUiModel({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.authorAvatarUrl,
    required this.timestampText,
    required this.text,
    required this.mediaUrls,
    required this.likesCount,
    required this.repostsCount,
    required this.commentsCount,
    required this.savesCount,
  });
}