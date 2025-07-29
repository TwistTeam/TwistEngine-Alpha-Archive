package openfl.display3D;

typedef UniformLocation = #if (!web && (!lime_doc_gen || lime_opengl || lime_opengles))
	lime.graphics.opengl.GLUniformLocation;
#else
	Dynamic;
#end
