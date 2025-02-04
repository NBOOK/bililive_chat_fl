import 'dart:ui';

import 'package:bililive_api_fl/bililive_api_fl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../creds.dart';
import '../global.dart';
import '../messages/multi.dart';
import 'dashboard.dart';
import 'stickers.dart';

class MessageInputWidget extends StatefulWidget {
  const MessageInputWidget({super.key});

  @override
  State<StatefulWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final TextEditingController _editController = TextEditingController();
  final FocusNode _textBoxFocusNode = FocusNode();
  bool _sendInProgress = false;
  bool _busy = false;
  int _length = 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 20,
      // Use a mixture of (a very small portion of) app primary color and light
      // gray to create some contrast between the content zone and the input
      // zone.
      // TODO: any better design choices for this?
      color: Color.alphaBlend(
        Colors.blue.withOpacity(0.15),
        // Theme.of(context).scaffoldBackgroundColor,
        Colors.grey.shade100,
      ),
      child: Row(
        children: [
          // Padding
          const SizedBox(width: 12),
          // Text field
          Expanded(
            child: TextField(
              controller: _editController,
              focusNode: _textBoxFocusNode,
              // Use gray to indicate busy state (but keep the input box enabled).
              style: TextStyle(
                  color: _busy
                      ? Colors.grey
                      : (_length > 20 ? Colors.red.shade700 : null)),
              decoration: const InputDecoration(
                hintText: 'Say something...',
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() {
                // TODO: this results in frequent UI rebuilds that may slow
                // down the app.
                _length = value.length;
              }),
              onSubmitted: (message) {
                if (message.isNotEmpty) {
                  _onSendText(message);
                } else {
                  Global.i.logger.d('Nothing to send');
                }
              },
            ),
          ),
          // Open emotion / sticker drawer
          IconButton(
            onPressed: () async {
              var stickerId = await showModalBottomSheet<String>(
                context: context,
                builder: (context) => StickerPicker(
                  roomId: Provider.of<MultiRoomProvider>(context, listen: false)
                      .current,
                  cred: Provider.of<BiliCredsProvider>(context, listen: false)
                      .credential,
                ),
              );
              if (stickerId != null) {
                _onSendSticker(stickerId);
              }
            },
            icon: const Icon(Icons.emoji_emotions),
            // Use gray to indicate busy state (but keep the button enabled).
            // TODO: better UX design?
            color: _busy ? Colors.grey : Colors.blue,
          ),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Characters count
              AnimatedOpacity(
                opacity: _length > 0 ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Text(
                    _length.toString(),
                    style: TextStyle(
                      color: _length > 20 ? Colors.red : Colors.grey.shade700,
                      fontSize: 12,
                      // Force monospaced character figures
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              // Send button
              IconButton(
                // Disable this button when busy
                // TODO: ternary operator results in ugly formatting. How to resolve this?
                onPressed: _busy
                    ? null
                    : () {
                        var message = _editController.text;
                        if (message.isNotEmpty) {
                          _onSendText(message);
                        } else {
                          // Global.i.logger.d('Nothing to send');

                          // Open personal dashboard
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => PersonalDashboard(
                              cred: Provider.of<BiliCredsProvider>(context,
                                      listen: false)
                                  .credential,
                            ),
                          );
                        }
                      },
                icon: _busy
                    ? const CircularProgressIndicator()
                    : (_length > 0
                        ? const Icon(Icons.send)
                        : const Icon(Icons.expand_less)),
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onSendText(String message) async {
    // Prevent re-entrance (is this ever necessary?)
    if (_sendInProgress) return;
    _sendInProgress = true;

    try {
      setState(() {
        _busy = true;
        // Temporarily set text length to 0
        _length = 0;
      });

      // Clear input box (to indicate to the user that the app has acknowledged
      // user input)
      _editController.text = '';
      // Re-focus the input box
      _textBoxFocusNode.requestFocus();

      var roomId =
          Provider.of<MultiRoomProvider>(context, listen: false).current;
      var creds = Provider.of<BiliCredsProvider>(context, listen: false);

      if (creds.simulateSend) {
        // Simulate send
        Global.i.logger.i('Send message "$message" to room $roomId');
        await Future.delayed(const Duration(seconds: 1));
      } else {
        var cred = creds.credential;
        if (cred == null) {
          // No cookies configured, ask for one
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              'No cookies have been configured, cannot send message',
            ),
          ));
          // Put the text back
          _editController.text = message;
        } else {
          await sendTextMessage(Global.i.dio, roomId, message, cred);
        }
      }
    } catch (e) {
      // Simple error handling
      Global.i.logger.e(e);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Failed to send message :(',
        ),
      ));
    } finally {
      _sendInProgress = false;
      setState(() {
        _busy = false;
        // Maintain correct length (this also works if the user have already
        // typed another message)
        // Unfortunately, state management is hard :(
        _length = _editController.text.length;
      });
    }
  }

  void _onSendSticker(String stickerId) async {
    // Prevent re-entrance (is this ever necessary?)
    if (_sendInProgress) return;
    _sendInProgress = true;

    try {
      setState(() {
        _busy = true;
      });

      var roomId =
          Provider.of<MultiRoomProvider>(context, listen: false).current;
      var credsProvider =
          Provider.of<BiliCredsProvider>(context, listen: false);
      var cred = credsProvider.credential;

      if (credsProvider.simulateSend) {
        // Simulate send
        Global.i.logger.i('Send sticker $stickerId to $roomId');
        await Future.delayed(const Duration(seconds: 1));
      } else if (cred == null) {
        // No cookies configured, ask for one
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'No cookies have been configured, cannot send sticker',
          ),
        ));
      } else {
        await sendStickerMessage(Global.i.dio, roomId, stickerId, cred);
      }
    } catch (e) {
      // Simple error handling
      Global.i.logger.e(e);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Failed to send sticker message :(',
        ),
      ));
    } finally {
      _sendInProgress = false;
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _editController.dispose();
    _textBoxFocusNode.dispose();
  }
}
