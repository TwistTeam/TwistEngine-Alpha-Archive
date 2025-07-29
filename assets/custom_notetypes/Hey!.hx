static final _noteHeyName = "Hey!";
function onCreateNote(I:Note) {
	if (i.noteType == _noteHeyName)
	{
		i.noSingAnimation = true;
	}
}
function goodNoteHit(note) {
	if (note.noAnimation || note.noteType != _noteHeyName) return;
	final char = note.gfNote && gf != null ? gf : boyfriend;
	final animCheck:String = char == gf ? 'cheer' : 'hey';
	if (char.hasAnimation(animCheck))
	{
		char.playAnim(animCheck, true);
		char.specialAnim = true;
		char.heyTimer = 0.6;
	}
}
function opponentNoteHit(note) {
	if (note.noAnimation || note.noteType != _noteHeyName) return;
	final char = note.gfNote && gf != null ? gf : dad;
	final animCheck:String = char == gf ? 'cheer' : 'hey';
	if (char.hasAnimation(animCheck))
	{
		char.playAnim(animCheck, true);
		char.specialAnim = true;
		char.heyTimer = 0.6;
	}
}