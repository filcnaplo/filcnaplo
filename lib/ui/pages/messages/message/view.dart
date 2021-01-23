import 'package:filcnaplo/ui/pages/messages/message/attachment.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:filcnaplo/data/models/message.dart';
import 'package:filcnaplo/data/models/recipient.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:filcnaplo/data/context/app.dart';
import 'package:filcnaplo/data/context/message.dart';
import 'package:filcnaplo/utils/format.dart';
import 'package:filcnaplo/ui/pages/messages/compose.dart';
import 'package:filcnaplo/ui/common/profile_icon.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:share/share.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:filcnaplo/generated/i18n.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:filcnaplo/helpers/archive_message.dart';

class MessageView extends StatefulWidget {
  final List<Message> messages;
  final updateCallback;

  archiveMessages(context, bool archiving) {
    messages.forEach((msg) => MessageArchiveHelper()
        .archiveMessage(context, msg, archiving, updateCallback));
  }

  deleteMessages(context) {
    messages.forEach((msg) =>
        MessageArchiveHelper().deleteMessage(context, msg, updateCallback));
  }

  MessageView(this.messages, this.updateCallback);

  @override
  _MessageViewState createState() => _MessageViewState();
}

class _MessageViewState extends State<MessageView> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        child: CupertinoScrollbar(
          child: ListView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.only(bottom: 12.0),
            children: widget.messages
                .map((message) => MessageViewTile(
                    message,
                    message == widget.messages.first,
                    message == widget.messages.last,
                    widget.archiveMessages,
                    widget.deleteMessages))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class MessageViewTile extends StatefulWidget {
  final Message message;
  final bool isFirst;
  final bool isLast;
  final archiveCallback;
  final deleteCallback;

  MessageViewTile(this.message, this.isFirst, this.isLast, this.archiveCallback,
      this.deleteCallback);

  @override
  _MessageViewTileState createState() => _MessageViewTileState();
}

class _MessageViewTileState extends State<MessageViewTile> {
  bool showRecipients = false;
  bool showBody = false;
  bool showQuoted = false;

  @override
  void initState() {
    super.initState();
    showBody = widget.isFirst;
  }

  Widget build(BuildContext context) {
    String messageContent = widget.message.content;
    List messageReplys = messageContent.split("-" * 20);
    String quotedMessage;
    if (messageReplys.length > 1) {
      quotedMessage = messageReplys.sublist(1).join("-" * 20);
      messageContent = messageReplys[0];
    }

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          (widget.isFirst)
              ? AppBar(
                  leading: BackButton(color: Theme.of(context).accentColor),
                  shadowColor: Colors.transparent,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  actions: <Widget>[
                      Tooltip(
                        message: capital(widget.message.deleted
                            ? I18n.of(context).messageRestore
                            : I18n.of(context).messageArchive),
                        child: IconButton(
                            icon: Icon(widget.message.deleted
                                ? FeatherIcons.arrowUp
                                : FeatherIcons.archive),
                            onPressed: () {
                              Navigator.pop(context);
                              widget.archiveCallback(
                                  context, !widget.message.deleted);
                            }),
                      ),
                      widget.message.deleted
                          ? Tooltip(
                              message: capital(I18n.of(context).messageDelete),
                              child: IconButton(
                                icon: Icon(FeatherIcons.trash2),
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.deleteCallback(context);
                                },
                              ))
                          : Container()
                    ])
              : Container(),
          widget.isFirst
              ? Padding(
                  padding:
                      EdgeInsets.only(left: 16.0, right: 16.0, bottom: 4.0),
                  child: Text(
                    widget.message.subject,
                    style: TextStyle(fontSize: 24.0),
                  ),
                )
              : Container(),
          RawMaterialButton(
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                leading: ProfileIcon(name: widget.message.sender),
                title: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.message.sender,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14.0),
                      ),
                    ),
                    SizedBox(width: 4.0),
                    Text(
                      formatDate(context, widget.message.date),
                      style: TextStyle(fontSize: 14.0, color: Colors.grey),
                    ),
                  ],
                ),
                subtitle: showBody
                    ? Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              (widget.message.recipients
                                          .map((r) => r.name)
                                          .contains(app.user.realName)
                                      ? I18n.of(context).messageToMe
                                      : I18n.of(context).messageTo(
                                          widget.message.recipients[0].name)) +
                                  (widget.message.recipients.length > 1
                                      ? " +" +
                                          (widget.message.recipients.length - 1)
                                              .toString()
                                      : ""),
                              style: TextStyle(fontSize: 13.0),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          widget.message.recipients.length > 1
                              ? IconButton(
                                  icon: Icon(
                                      showRecipients
                                          ? FeatherIcons.chevronUp
                                          : FeatherIcons.chevronDown,
                                      size: 18.0),
                                  padding: EdgeInsets.zero,
                                  constraints:
                                      BoxConstraints.tight(Size(28.0, 32.0)),
                                  onPressed: () => setState(
                                      () => showRecipients = !showRecipients),
                                )
                              : Container(),
                        ],
                      )
                    : Text(
                        escapeHtml(widget.message.content),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Tooltip(
                      message: capital(I18n.of(context).messageReply),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(FeatherIcons.cornerUpLeft),
                        constraints: BoxConstraints.tight(Size(32.0, 32.0)),
                        onPressed: () {
                          messageContext = MessageContext();
                          messageContext.subject =
                              "RE: " + widget.message.subject;
                          messageContext.recipients.add(
                            Recipient.fromJson(
                                {"nev": widget.message.sender, "tipus": {}}),
                          );
                          messageContext.replyId = widget.message.messageId;

                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => NewMessagePage()));
                        },
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Tooltip(
                      message: capital(I18n.of(context).messageShare),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(FeatherIcons.share2),
                        constraints: BoxConstraints.tight(Size(32.0, 32.0)),
                        onPressed: () {
                          Share.share(
                            escapeHtml(widget.message.content) +
                                "\n\n" +
                                I18n.of(context).messageShareFooter(
                                    widget.message.sender,
                                    DateFormat("yyyy. MM. dd.")
                                        .format(widget.message.date)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              onPressed: !widget.isFirst
                  ? () => setState(() => showBody = !showBody)
                  : null),
          showRecipients
              ? Container(
                  margin:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Wrap(
                    spacing: 12.0,
                    children: () {
                      return widget.message.recipients
                          .map((r) => Chip(
                              avatar: ProfileIcon(name: r.name, size: .7),
                              label: Text(r.name)))
                          .toList();
                    }(),
                  ),
                )
              : Container(),
          showBody
              ? Padding(
                  padding: EdgeInsets.all(12.0),
                  child: app.settings.renderHtml
                      ? Html(
                          data: messageContent,
                          onLinkTap: (url) async {
                            if (await canLaunch(url))
                              await launch(url);
                            else
                              throw '[ERROR] MessageView.build: Invalid URL';
                          },
                        )
                      : SelectableLinkify(
                          text: escapeHtml(messageContent),
                          onOpen: (url) async {
                            if (await canLaunch(url.url))
                              await launch(url.url);
                            else
                              throw '[ERROR] MessageView.build: nvalid URL';
                          },
                        ),
                )
              : Container(),
          quotedMessage != null
              ? FlatButton(
                  child: Text(
                    showQuoted
                        ? I18n.of(context).messageHideQuoted
                        : I18n.of(context).messageShowQuoted,
                    style: TextStyle(color: app.settings.appColor),
                  ),
                  onPressed: () => setState(() => showQuoted = !showQuoted),
                )
              : Container(),
          showQuoted
              ? Padding(
                  padding: EdgeInsets.fromLTRB(24.0, 12.0, 12.0, 12.0),
                  child: app.settings.renderHtml
                      ? Html(
                          data: quotedMessage,
                          onLinkTap: (url) async {
                            if (await canLaunch(url))
                              await launch(url);
                            else
                              throw '[ERROR] MessageView.build: Invalid URL';
                          },
                        )
                      : SelectableLinkify(
                          text: escapeHtml(quotedMessage),
                          onOpen: (url) async {
                            if (await canLaunch(url.url))
                              await launch(url.url);
                            else
                              throw '[ERROR] MessageView.build: Invalid URL';
                          },
                        ),
                )
              : Container(),
          showBody
              ? Column(
                  children: widget.message.attachments
                      .map((attachment) => AttachmentTile(attachment))
                      .toList())
              : Container(),
          (!widget.isLast) ? Divider() : Container(),
        ],
      ),
    );
  }
}
