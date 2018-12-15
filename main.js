$(".hide-block").hide()

$(".first-step").click(function(){
	$(".second-step .hide-block").hide("slow");
	$(".third-step .hide-block").hide("slow");
	$(".first-step .hide-block").toggle("slow");
});

$(".second-step").click(function(){
	$(".first-step .hide-block").hide("slow");
	$(".third-step .hide-block").hide("slow");
	$(".second-step .hide-block").toggle("slow");
});

$(".third-step").click(function(){
	$(".first-step .hide-block").hide("slow");
	$(".second-step .hide-block").hide("slow");
	$(".third-step .hide-block").toggle("slow");
});