# -------------------------------------------------------
# AWS SQS - Messaging Queue
# -------------------------------------------------------

resource "aws_sqs_queue" "main" {
  name                      = "steam-messaging-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600
  receive_wait_time_seconds = 0

  tags = {
    Name    = "steam-messaging-queue"
    Project = "steam-indio"
  }
}
