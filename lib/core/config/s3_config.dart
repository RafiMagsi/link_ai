class S3Config {
  /// S3 endpoint URL
  /// Example: 'https://s3.amazonaws.com' for AWS S3
  /// Or custom S3-compatible service endpoint
  static const String endpoint = 'https://s3.amazonaws.com';

  /// AWS region (e.g., 'us-east-1', 'us-west-2')
  /// Fill in your region
  static const String region = 'us-east-1';

  /// S3 bucket name
  /// Fill in your bucket name
  static const String bucket = '';

  /// AWS Access Key ID
  /// Fill in your access key
  static const String accessKey = '';

  /// AWS Secret Access Key
  /// Fill in your secret key
  static const String secretKey = '';

  /// S3 base URL for public media access
  /// Example: 'https://your-bucket-name.s3.amazonaws.com'
  /// If empty, will be constructed from endpoint + bucket
  static const String publicBaseUrl = '';

  /// Whether to use path-style S3 URLs (true) or virtual-hosted-style (false)
  static const bool usePathStyle = true;
}
