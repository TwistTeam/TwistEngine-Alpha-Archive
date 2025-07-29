package game.backend.data;

import game.objects.game.notes.Note.DirectionNote;

@:final class StrumsManiaData{
	public static var data:Map<String, Array<DirectionNote>> = [
		'1K' => ['down'], // lol
		'2K' => ['left', 'right'], // lol
		'3K' => ['left', 'up', 'right'], // lol
		'4K' => ['left', 'down', 'up', 'right'],
		'5K' => ['left', 'down', 'space', 'up', 'right'],
		'6K' => ['left', 'down', 'right', 'extra_left', 'extra_up', 'extra_right'],
		'7K' => ['left', 'down', 'right', 'space', 'extra_left', 'extra_up', 'extra_right'],
		'8K' => ['left', 'down', 'up', 'right', 'extra_left', 'extra_down', 'extra_up', 'extra_right'],
		'9K' => ['left', 'down', 'up', 'right', 'space', 'extra_left', 'extra_down', 'extra_up', 'extra_right']
	];
}
