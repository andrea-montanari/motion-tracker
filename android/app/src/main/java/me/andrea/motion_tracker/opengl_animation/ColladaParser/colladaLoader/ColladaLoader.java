package me.andrea.motion_tracker.opengl_animation.ColladaParser.colladaLoader;

import android.content.Context;

import me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures.AnimatedModelData;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures.MeshData;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures.AnimationData;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures.SkeletonData;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.dataStructures.SkinningData;

import me.andrea.motion_tracker.opengl_animation.ColladaParser.xmlParser.XmlNode;
import me.andrea.motion_tracker.opengl_animation.ColladaParser.xmlParser.XmlParser;

public class ColladaLoader {

	public static AnimatedModelData loadColladaModel(String colladaFile, int maxWeights, Context context) {
		XmlNode node = XmlParser.loadXmlFile(colladaFile, context);

		SkinLoader skinLoader = new SkinLoader(node.getChild("library_controllers"), maxWeights);
		SkinningData skinningData = skinLoader.extractSkinData();

		SkeletonLoader jointsLoader = new SkeletonLoader(node.getChild("library_visual_scenes"), skinningData.jointOrder);
		SkeletonData jointsData = jointsLoader.extractBoneData();

		GeometryLoader g = new GeometryLoader(node.getChild("library_geometries"), skinningData.verticesSkinData);
		MeshData meshData = g.extractModelData();

		return new AnimatedModelData(meshData, jointsData);
	}

	public static AnimationData loadColladaAnimation(String colladaFile, Context context) {
		XmlNode node = XmlParser.loadXmlFile(colladaFile, context);
		XmlNode animNode = node.getChild("library_animations");
		XmlNode jointsNode = node.getChild("library_visual_scenes");
		AnimationLoader loader = new AnimationLoader(animNode, jointsNode);
		AnimationData animData = loader.extractAnimation();
		return animData;
	}

}
