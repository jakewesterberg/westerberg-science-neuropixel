function menuFunction() {
	var x = document.getElementById("top-menu");
	x.style.height = ("14" === x.style.height.substring(0,2)) ? "2.8125em" : "14.375em";
}

function menuResizeFunction() {
	var x = document.getElementById("top-menu");
	x.style.height = "2.8125em";
}

function scrollToHash() {
	var x = window.location.hash;
	if (0 == x.length) return;
	var y = document.querySelector(x).offsetTop;
	var offset = document.getElementById("top-menu").offsetHeight + 20;
	window.scroll(0, y - offset);
}

function fixNavbarOnScroll() {
	var x = document.getElementById("top-menu");
	var y = document.getElementById("nav-bar");
	console.log(window.scrollY);
	if (45<window.scrollY) { y.style.top = 0; y.style.position = "fixed"; }
	if (window.scrollY<45) { y.style.top = x.style.bottom; y.style.position = "absolute"; }
}
