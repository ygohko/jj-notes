#let emph-color = rgb("#177")
#let command-color = rgb("#911")

#set page(
  "us-letter",
  margin: 0.5in,
  columns: 2,
)

#set text(
  size: 8.5pt,
  font: "IBM Plex Sans JP"
)
#show heading.where(level: 1): set align(center)

#show raw: it => text(font: "PlemolJP", weight: "semibold", fill: command-color, it)
#show emph: it => text(fill: emph-color, weight: "semibold", it)


= JJ リファレンス

// This is a _reference_ for the Jujutsu version control system. It exists to help you learn and
// remember the details of Jujutsu, once you have already grokked the basics.

== モデル

JujutsuリポジトリはDAG(有向非巡回グラフ)で、そのノードは_チェンジ_と呼ばれます。それぞれのチェンジは
以下のものを持っています:

- リポジトリディレクトリ内のファイルシステムの状態。それぞれのチェンジがディレクトリとすべての
  ファイルの完全なコピーを保持していることを想像してもよいですが、実際には、`jj`はもっと効率的にそれを
  行っています。
- ファイルの_衝突_。チェンジ内のファイルには様々な理由で衝突があるかもしれません。それらの衝突は
  そのチェンジにローカルなものです。(`git`と異なり、衝突は`jj`を使うことを妨げません。)
- 一つかそれ以上の_親_のチェンジ。ですが、親がなく常に空ディレクトリを持つルートのチェンジも
  あります。
- テキストによるチェンジの_説明_、別名 コミットメッセージ。これは常に存在しますが、デフォルトは
  空文字列です。

いくつかの付加情報がDAGに添えられています:

- チェンジのうち一つだけが_作業中のチェンジ_で、`@`で表されています。この文書ではそれを
  "作業コピーのリビジョン"と呼びます。(これは`git`の`HEAD`に似ています。)
- チェンジには単一な文字列のラベル _ブックマーク_があるかもしれません。(`git`と連携する場合、
  ブックマークはブランチ名として機能します。)
- リポジトリは(Githubのような)_リモートリポジトリ_と関連付けされているかもしれません。その場合、
  `push`または`fetch`時に、`jj`はそれぞれのブックマークの_最後に知っている位置_を
  `ブックマーク@リモート`で表して記録します(例: `feat-ui@origin`)。

ほとんどの`jj`のコマンドはローカルリポジトリのDAGを何らかの方法で修正します。いくつかの一般的な
ルールが、リポジトリがどのように変化するかを予測する手助けになるでしょう:

- あるチェンジを`@`で指定すると、リポジトリディレクトリはそのチェンジのファイルと一致するように
  更新されます。
- `@`が指しているチェンジを削除した場合、`@`はその親から作られた新しい空のチェンジに移動します。 
- チェンジにファイルの修正と説明がなく、`@`やブックマークから参照されていない場合、静かに闇へと
  消えていきます。
- チェンジは差分を表しています。チェンジを移動すると新しい親に差分を適用しようとします。これは
  マージコンフリクトを起こすかもしれません。
- 多くのコマンドはデフォルトでは`@`に作用します。ほぼ全てのコマンドは他のチェンジに作用させるために
  `-r/--revision`の引数を取ることができます。
  // (Of the commands in the Cheat Sheet that show `@`, all can be applied to a
  // different change using `-r` except for `jj bookmark move` and `jj restore`, which take `--from`
  // and `--to` arguments instead.)

=== ファイルの衝突

作業中のチェンジ(`@`)に_ファイルの衝突_がある場合、単に衝突マーカー(`<<<<<<<`、`=======`など)が
無くなるようにそのファイルを編集すれば解決されます。バイナリファイルの場合は、あるべきバージョンの
ファイルに置き換えてください。この目的には`jj restore`が便利かもしれません。(`git`と異なり、
ファイルの衝突は作業を妨げません。)

=== jj git push

`jj git push`はチェンジをローカルリポジトリからリモートリポジトリにコピーします。ローカルの
チェンジが最後のプッシュ時から修正されている場合、それはリモートリポジトリの新しいチェンジに
なります (`git`の強制プッシュのように以前のコミットを新しいコミットで置き換えます)。
この操作をうっかり`main`に行うことを防ぐため、`jj git push`は主要なブランチにプッシュされた
全てのチェンジを変更不能にします。これらのチェンジは必要ならば引き続き編集できますが、それには
`--ignore-immutable`フラグを与える必要があります。

すべてのローカルブックマークは同様にリモートリポジトリにコピーされます。ブックマークがローカルと
リモートの両方にある場合、`jj`はその(ローカルに記録された)_最後に見ていた位置_が
リモートリポジトリの現在の位置と一致するかを調べます。一致する場合、リモートリポジトリの
ブックマーク位置は更新されます。そうでなければこのコマンドは失敗し、(あなたが最後にプッシュしてから
誰かがブックマークを更新したということなので)まずは`jj git fetch`を行うよう知らせます。

=== jj git fetch

`jj git fetch`はリモートリポジトリのチェンジをローカルリポジトリにコピーします。チェンジが
リモートリポジトリで修正された場合、それはローカルでも新しいチェンジに変わります。ですが、
ほとんどの場合は単に新しいチェンジを取得します。

ローカルのブックマークはリモートリポジトリにあるチェンジと一致するように進みます。しかし、
リモート上のブックマークのチェンジがローカルのチェンジの子孫でない場合、`jj git fetch`はその
ブックマークのもう一つのコピーを作ります。
これはブックマーク名は単一であるというルールを破るので、_ブックマークの衝突_と呼ばれます。
(`git pull`がマージコンフリクトを起こすことに似ています。)この"ブックマークの衝突"を
どう解決するかはあなた次第です。それにはいくつかの選択肢があります:

- 二つのチェンジをマージしたい場合、`jj new チェンジID-1 チェンジID-2`を行い、衝突を解決し、その後
  `jj bookmark move ブックマーク名`でブックマークを更新します。 (チェンジIDは
  `jj bookmark list ブックマーク名`を実行すると取得できます。)
- 二つのチェンジのうち一つを捨てて単にもう一方を使いたい場合、残したいチェンジに対し
  `jj bookmark move ブックマーク名 -t チェンジID`を行います。
- 一方のチェンジがもう一方のチェンジの_後_に来るようリベースしたい場合、
  `jj rebase -b チェンジID-2 -d チェンジID-1`を行い、その後
  `jj bookmark move ブックマーク名 -t チェンジID-2`を行います。これは二つ目のチェンジのみではなく、
  一つ目のチェンジから分岐したすべてのチェンジをリベースします。

== コマンド

=== 共通設定のコマンド

```
jj config set --user user.name  自分の名前
jj config set --user user.email 自分のEMAIL
jj config set --user ui.editor  自分のエディター

jj config edit --user  // 設定ファイルを手で編集する
```

`--user`の代わりに`--repo`を渡すと、リポジトリ固有の優先的な設定を変更できます。

=== リポジトリのコマンド

- `jj git init`、または`jj git clone URL [送り先]`。gitバックエンドのリポジトリを作成またはクローン
  する。
- `jj git init --colocate`。既存の`git`リポジトリが`jj`リポジトリにもなるようにする。

=== ローカルリポジトリを編集する

添付のJJ チートシートでは`jj`リポジトリを編集するためのもっとも一般的で基本的なコマンドを視覚的に
表します。

他の`jj`コマンドの組み合わせとして考えるとよい、いくつかの"エイリアス"コマンドもあります:

- `jj commit`。`jj describe; jj new`の省略形。
- `jj bookmark set ブックマーク名`。ブックマークの`create`または`move`、どちらか有効なほう。

// ## Commands
// 
// - `jj abandon REVISION`: REVISION defaults to `@`. Delete the change (delete that node in the
//   graph). It's children now point at its parent(s). This could introduce conflicts. If `@` is the
//   same as `REVISION`, make `@` be a new empty change on top of the parent.
// - `jj backout -r REVISION_r -d REVISION_d`: Create a new change (new node). Its parent is
//   `REVISION_d`. Its modification is the opposite of the modification of `REVISION_r`. Its
//   description is `Back out "THE DESCRIPTION OF REVISION_r"`.
// - `jj bookmark create BOOKMARK -r REVISION`. REVISION defaults to `@`. Label REVISION with a
//   bookmark named BOOKMARK. (Does propagate to remote.)
// - `jj bookmark delete BOOKMARK`. Deletes the bookmark label named BOOKMARK. (Does propagate to
//   remote.)
// - `jj bookmark list`. Lists all bookmarks and the changes they point at.
// - `jj bookmark rename BOOKMARK_OLD BOOKMARK_NEW`. Renames the bookmark. (QUESTION: Is this the same
//   as delete and then create? How does it interact with pushing? If you rename&push, does it delete
//   the old branch on the remote?) Is local only!
// - `jj bookmark move BOOKMARK --to REVISION`. Move the bookmark label to point at REVISION instead.
//   REVISION defaults to `@`.
// - `jj describe`. Open an editor to set the description of the current change. Or say `jj describe -m
//   "COMMIT MESSAGE"` to specify it on the command line.
// - `jj show`. Print the description for `@`.
// - `jj diff PATHS...`. Show the diff for the files at PATHS, between this revision (`@`) and its
//   parent (`@-`). You can pass `--from REVISION` and `--to REVISION` to see the diff between
//   arbitrary changes. TODO: compare to `jj interdiff`.
// - `jj interdiff PATHS...`. TODO. Is this advanced?
// - `jj edit REVISION`. Move `@` (the "working-copy revision") to point at REVISION.
// - `jj file track/untrack`.
// - `jj log PATHS...`. Prints the DAG, limited to those nodes that modified PATHS. QUESTION: when do
//   you need to run `jj log -r ..`?
// - `jj new`. Create a new empty commit on top of `@`, and edit it (move `@` to it). `-m "MESSAGE"`
//   additionally sets its description. `jj new REVISIONS...` specifies the parents of the new commit;
//   if there are multiple parents you're making a merge commit.
// - `jj status` (alias: `jj st`). Print some basic info about the repo.
// - `jj restore --from REVISION PATHS...`. Make the files for this commit match those at REVISION.
// - `jj undo`. Undo the last thing you did.
// - `jj squash`. Move all changes from this revision to its parent.
// - `jj rebase`. TODO.
// - `jj resolve!!`. TODO.
// 
// ## Advanced Commands
// 
// - `jj bookmark forget BOOKMARK`. Deletes the bookmark label named BOOKMARK, but "forgets" that it
//   exists remotely. It will be recreated if you pull again!
// - `jj bookmark track BOOKMARK@REMOTE`. TODO
// - `jj bookmark untrack BOOKMARK@REMOTE`. TODO
// - `jj duplicate`. TODO
// - `jj new --insert-before REVISION` and `jj new --insert-after REVISION`. TODO.
// - `jj prev` and `jj next`?
// - `jj simplify-parents`. Simplifies the DAG in a lossless way. (A -> B, A -> C, B ->+ C becomes A ->
//   B, B ->+ C).
// - `jj workspace`. TODO.
// - `jj undo OPERATION`. TODO.
// - `jj split`. Split a commit in two, with an editor.
// - `jj parallelize`. TODO.
