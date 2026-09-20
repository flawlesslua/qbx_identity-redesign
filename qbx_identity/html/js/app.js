const RESOURCE = "qbx_identity";

const locale = {};

const icons = {
    sex: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="10" cy="14" r="5"/><path d="M19 5l-5.5 5.5"/><path d="M14 5h5v5"/></svg>',
    height: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v18"/><path d="M8 6l4-3 4 3"/><path d="M8 18l4 3 4-3"/></svg>',
    cash: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2.6"/></svg>',
    bank: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10h18"/><path d="M12 3l9 5H3z"/><path d="M6 10v7"/><path d="M12 10v7"/><path d="M18 10v7"/><path d="M3 21h18"/></svg>',
    dob: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18"/><path d="M8 3v4"/><path d="M16 3v4"/></svg>',
    flag: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 21V4"/><path d="M5 4h13l-2.5 4L18 12H5"/></svg>',
    job: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="7" width="18" height="13" rx="2"/><path d="M9 7V5h6v2"/></svg>',
    gang: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 20v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9.5" cy="7" r="3.5"/><path d="M22 20v-2a4 4 0 0 0-3-3.87"/></svg>',
    clock: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.5 2"/></svg>'
};

const state = {
    slots: [],
    selected: 1,
    canDelete: false,
    nations: [],
    nationality: "",
    gender: 0,
    cursor: -1,
    busy: false,
    view: "select",
    spawnLocations: [],
    spawnLast: null,
    spawnSelected: "last"
};

const pinIcon = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21s7-6.2 7-11a7 7 0 1 0-14 0c0 4.8 7 11 7 11z"/><circle cx="12" cy="10" r="2.6"/></svg>';
const clockIcon = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.5 2"/></svg>';

const limits = {
    minHeight: 120,
    maxHeight: 220,
    minYear: 1900,
    maxYear: 2006,
    maxWords: 5,
    maxText: 50
};

const el = {
    body: document.body,
    scrim: document.getElementById("scrim"),
    viewSelect: document.getElementById("view-select"),
    viewCreate: document.getElementById("view-create"),
    name: document.getElementById("name"),
    count: document.getElementById("count"),
    detailsLabel: document.getElementById("details-label"),
    chips: document.getElementById("chips"),
    emptyHint: document.getElementById("empty-hint"),
    slots: document.getElementById("slots"),
    play: document.getElementById("play"),
    playLabel: document.getElementById("play-label"),
    del: document.getElementById("delete"),
    confirm: document.getElementById("confirm"),
    confirmText: document.getElementById("confirm-text"),
    combo: document.getElementById("combo"),
    comboInput: document.getElementById("nationality"),
    comboList: document.getElementById("combo-list"),
    firstname: document.getElementById("firstname"),
    lastname: document.getElementById("lastname"),
    height: document.getElementById("height"),
    day: document.getElementById("dob-day"),
    month: document.getElementById("dob-month"),
    year: document.getElementById("dob-year"),
    create: document.getElementById("create"),
    back: document.getElementById("back"),
    viewSpawn: document.getElementById("view-spawn"),
    rail: document.getElementById("rail"),
    spotKicker: document.getElementById("spot-kicker"),
    spotName: document.getElementById("spot-name"),
    spotDesc: document.getElementById("spot-desc"),
    spotTags: document.getElementById("spot-tags"),
    spawnConfirm: document.getElementById("spawn-confirm")
};

const HOVER_TARGETS = ".hex, .ctrl, .link, .play, .btn, .pill, .combo-item, .rail-item";

const SOUND_FILE = "sounds/hover.ogg";

const sound = {
    enabled: true,
    unlocked: false,
    last: null
};

const hover = {
    volume: 0.35,
    rate: 1,
    throttle: 60,
    size: 4,
    pool: null,
    index: 0,
    lastPlayed: 0
};

const click = {
    enabled: true,
    volume: 0.5,
    rate: 0.85,
    throttle: 40,
    size: 2,
    pool: null,
    index: 0,
    lastPlayed: 0
};

function buildChannel(channel) {
    channel.pool = [];
    channel.index = 0;

    for (let i = 0; i < channel.size; i++) {
        const audio = new Audio(SOUND_FILE);
        audio.preload = "auto";
        audio.volume = channel.volume;
        audio.playbackRate = channel.rate;
        audio.preservesPitch = false;
        audio.mozPreservesPitch = false;
        audio.webkitPreservesPitch = false;
        channel.pool.push(audio);
    }
}

function unlockSound() {
    if (sound.unlocked) return;

    sound.unlocked = true;

    const audio = new Audio(SOUND_FILE);
    audio.volume = 0;

    const started = audio.play();

    if (started && started.then) {
        started.then(() => {
            audio.pause();
            audio.currentTime = 0;
        }).catch(() => {});
    }
}

function playChannel(channel) {
    if (!sound.enabled || !channel.pool || !channel.pool.length) return;

    const now = performance.now();

    if (now - channel.lastPlayed < channel.throttle) return;

    channel.lastPlayed = now;

    const audio = channel.pool[channel.index];
    channel.index = (channel.index + 1) % channel.pool.length;
    audio.volume = channel.volume;
    audio.playbackRate = channel.rate;
    audio.currentTime = 0;
    audio.play().catch(() => {});
}

function playHover() {
    playChannel(hover);
}

function playClick() {
    if (!click.enabled) return;

    playChannel(click);

    hover.lastPlayed = performance.now();
}

function applyChannel(channel, config) {
    if (!config) return;

    if (typeof config.volume === "number") {
        channel.volume = Math.max(0, Math.min(1, config.volume));
    }

    if (typeof config.rate === "number") {
        channel.rate = Math.max(0.25, Math.min(4, config.rate));
    }

    if (typeof config.throttle === "number") {
        channel.throttle = Math.max(0, config.throttle);
    }

    if (typeof config.pool === "number") {
        channel.size = Math.max(1, Math.floor(config.pool));
    }
}

function applySound(config) {
    if (!config) return;

    sound.enabled = config.enabled !== false;

    applyChannel(hover, config);

    if (config.click) {
        click.enabled = config.click.enabled !== false;
        applyChannel(click, config.click);
    }

    if (!hover.pool) buildChannel(hover);
    if (!click.pool) buildChannel(click);
}

function text(key, fallback) {
    return locale[key] || fallback;
}

function post(name, payload) {
    return fetch("https://" + RESOURCE + "/" + name, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify(payload || {})
    }).catch(() => {});
}

function money(value) {
    return "$" + Math.floor(value || 0).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function relativeTime(unix) {
    if (!unix) return text("never_played", "Never played");

    const diff = Math.floor(Date.now() / 1000) - unix;
    if (diff < 3600) return text("time_now", "Just now");

    const hours = Math.floor(diff / 3600);
    if (hours < 24) return text("time_hours", "{n} hours ago").replace("{n}", hours);

    const days = Math.floor(hours / 24);
    if (days < 30) return text("time_days", "{n} days ago").replace("{n}", days);

    const months = Math.floor(days / 30);
    if (months < 12) return text("time_months", "{n} months ago").replace("{n}", months);

    return text("time_years", "{n} years ago").replace("{n}", Math.floor(months / 12));
}

function hexLayout(count) {
    const stepX = 84;
    const stepY = 68;
    const hexW = 76;
    const hexH = 86;

    let bottom = count;
    let top = 0;

    if (count > 3) {
        bottom = Math.ceil(count / 2);
        top = count - bottom;
    }

    const positions = [];
    for (let i = 0; i < bottom; i++) positions.push({ x: i * stepX, y: top > 0 ? stepY : 0 });
    for (let i = 0; i < top; i++) positions.push({ x: stepX / 2 + i * stepX, y: 0 });

    const width = Math.max(bottom * stepX - (stepX - hexW), stepX / 2 + top * stepX - (stepX - hexW));
    const height = (top > 0 ? stepY : 0) + hexH;

    return { positions: positions, width: width, height: height };
}

function buildSlots() {
    const layout = hexLayout(state.slots.length);

    el.slots.style.width = layout.width + "px";
    el.slots.style.height = layout.height + "px";
    el.slots.innerHTML = "";

    state.slots.forEach((slot, i) => {
        const hex = document.createElement("div");
        hex.className = "hex" + (slot.filled ? " filled" : "");
        hex.style.left = layout.positions[i].x + "px";
        hex.style.top = layout.positions[i].y + "px";

        const inner = document.createElement("div");
        inner.className = "inner";
        inner.textContent = slot.filled ? String(slot.id) : "+";

        hex.appendChild(inner);
        hex.addEventListener("click", () => select(slot.id));
        el.slots.appendChild(hex);
    });
}

function slotById(id) {
    return state.slots.find((slot) => slot.id === id);
}

function addChip(icon, value) {
    const node = document.createElement("div");
    node.className = "chip";
    node.innerHTML = '<div class="ico">' + icons[icon] + "</div><span></span>";
    node.querySelector("span").textContent = value;
    el.chips.appendChild(node);
}

function render() {
    const slot = slotById(state.selected);

    document.querySelectorAll(".hex").forEach((hex, i) => {
        hex.classList.toggle("active", state.slots[i].id === state.selected);
    });

    el.count.textContent = text("character", "CHARACTER") + " " + state.selected + " / " + state.slots.length;
    el.chips.innerHTML = "";

    document.querySelectorAll(".ctrl").forEach((ctrl) => {
        ctrl.classList.toggle("disabled", state.slots.length < 2);
    });

    if (!slot || !slot.filled) {
        el.name.textContent = text("empty_slot", "Empty Slot");
        el.name.classList.add("empty");
        el.detailsLabel.style.display = "none";
        el.chips.style.display = "none";
        el.emptyHint.style.display = "block";
        el.del.classList.add("disabled");
        el.playLabel.textContent = text("create", "CREATE CHARACTER");
        return;
    }

    el.name.textContent = slot.firstname + " " + slot.lastname;
    el.name.classList.remove("empty");
    el.detailsLabel.style.display = "block";
    el.chips.style.display = "flex";
    el.emptyHint.style.display = "none";
    el.del.classList.toggle("disabled", !state.canDelete);
    el.playLabel.textContent = text("play", "PLAY");

    addChip("sex", slot.gender === 1 ? text("female", "Female") : text("male", "Male"));
    if (slot.height) addChip("height", slot.height + " cm");
    if (slot.birthdate) addChip("dob", slot.birthdate);
    if (slot.nationality) addChip("flag", slot.nationality);
    addChip("cash", money(slot.cash));
    addChip("bank", money(slot.bank));
    if (slot.job) addChip("job", slot.jobGrade ? slot.job + " — " + slot.jobGrade : slot.job);
    if (slot.gang) addChip("gang", slot.gangGrade ? slot.gang + " — " + slot.gangGrade : slot.gang);
    addChip("clock", relativeTime(slot.lastLoggedOut));
}

function select(id) {
    if (state.selected === id) return;

    state.selected = id;
    render();
    post("selectSlot", { slot: id });
}

function step(direction) {
    if (state.slots.length < 2) return;

    const index = state.slots.findIndex((slot) => slot.id === state.selected);
    const next = (index + direction + state.slots.length) % state.slots.length;

    playHover();
    select(state.slots[next].id);
}

function showView(name) {
    state.view = name;
    el.viewSelect.classList.toggle("on", name === "select");
    el.viewCreate.classList.toggle("on", name === "create");
    el.viewSpawn.classList.toggle("on", name === "spawn");
    el.scrim.classList.toggle("deep", name === "create");
    el.scrim.classList.toggle("rail", name === "spawn");
}

function railItem(entry, icon) {
    const item = document.createElement("div");
    item.className = "rail-item";
    item.dataset.id = entry.id;
    item.innerHTML = '<div class="rail-hexwrap"><div class="rail-hex"><div class="inner">' + icon + '</div></div></div><div class="rail-label"></div>';
    item.querySelector(".rail-label").textContent = entry.label || entry.name || "";
    item.addEventListener("click", () => selectSpawn(entry.id));
    return item;
}

function railPill(entry) {
    const item = document.createElement("div");
    item.className = "rail-item rail-pill";
    item.dataset.id = entry.id;
    item.innerHTML = '<div class="rail-ico">' + clockIcon + '</div><div class="rail-label"></div>';
    item.querySelector(".rail-label").textContent = entry.label || text("spawn_last", "Last Location");
    item.addEventListener("click", () => selectSpawn(entry.id));
    return item;
}

function buildRail() {
    el.rail.innerHTML = "";

    if (state.spawnLast) {
        el.rail.appendChild(railPill(state.spawnLast));

        const divider = document.createElement("div");
        divider.className = "rail-divider";
        el.rail.appendChild(divider);
    }

    state.spawnLocations.forEach((location) => el.rail.appendChild(railItem(location, pinIcon)));
}

function renderSpawn() {
    const isLast = state.spawnSelected === "last";
    const data = isLast ? state.spawnLast : state.spawnLocations.find((l) => l.id === state.spawnSelected);

    if (!data) return;

    document.querySelectorAll(".rail-item").forEach((item) => {
        item.classList.toggle("active", item.dataset.id === state.spawnSelected);
    });

    el.spotKicker.textContent = isLast ? text("spawn_resume", "Resume from your last spot") : text("spawn_pick", "Choose an arrival point");
    el.spotName.textContent = data.name || "";
    el.spotDesc.textContent = data.desc || "";
    el.spotTags.innerHTML = "";

    (data.tags || []).forEach((value) => {
        const tag = document.createElement("div");
        tag.className = "tag";
        tag.textContent = value;
        el.spotTags.appendChild(tag);
    });
}

function selectSpawn(id) {
    if (state.spawnSelected === id) return;

    state.spawnSelected = id;
    renderSpawn();
    post("previewSpawn", { id: id });
}

function stepSpawn(direction) {
    const order = [];

    if (state.spawnLast) order.push("last");
    state.spawnLocations.forEach((l) => order.push(l.id));

    if (order.length < 2) return;

    const index = order.indexOf(state.spawnSelected);

    playHover();
    selectSpawn(order[(index + direction + order.length) % order.length]);
}

function openSpawn(data) {
    applySound(data.sound);
    state.spawnLocations = data.locations || [];
    state.spawnLast = data.last || null;
    state.spawnSelected = state.spawnLast ? "last" : (state.spawnLocations[0] && state.spawnLocations[0].id);

    el.confirm.classList.remove("open");
    el.body.classList.remove("hidden");

    showView("spawn");
    buildRail();
    renderSpawn();
}

function section(name) {
    return document.querySelector('.section[data-section="' + name + '"]');
}

function clearErrors() {
    document.querySelectorAll(".section").forEach((node) => node.classList.remove("has-error"));
    document.querySelectorAll(".field").forEach((node) => node.classList.remove("invalid"));
}

function showError(name, message, fields) {
    const node = section(name);
    if (!node) return;

    node.classList.add("has-error");
    node.querySelector(".error-msg").textContent = message;

    if (fields) {
        fields.forEach((field) => {
            if (field && field.parentElement) field.parentElement.classList.add("invalid");
        });
    }
}

function renderCombo(filter) {
    const query = (filter || "").trim().toLowerCase();
    const matches = state.nations.filter((n) => n.toLowerCase().indexOf(query) !== -1);

    el.comboList.innerHTML = "";
    state.cursor = -1;

    if (matches.length === 0) {
        const empty = document.createElement("div");
        empty.className = "combo-empty";
        empty.textContent = text("combo_empty", "No results.");
        el.comboList.appendChild(empty);
        return;
    }

    matches.forEach((n) => {
        const item = document.createElement("div");
        item.className = "combo-item" + (n === state.nationality ? " chosen" : "");
        item.textContent = n;
        item.addEventListener("mousedown", (event) => {
            event.preventDefault();
            state.nationality = n;
            el.comboInput.value = n;
            el.combo.classList.remove("open");
            section("nationality").classList.remove("has-error");
        });
        el.comboList.appendChild(item);
    });
}

function daysInMonth(month, year) {
    if (month === 2) return (year % 400 === 0 || (year % 100 !== 0 && year % 4 === 0)) ? 29 : 28;
    if (month === 4 || month === 6 || month === 9 || month === 11) return 30;
    return 31;
}

function pad(value) {
    return String(value).length === 1 ? "0" + String(value) : String(value);
}

function validName(value) {
    if (!/^[A-Za-z ]+$/.test(value)) return false;
    if (value.length > limits.maxText) return false;
    return value.split(" ").filter(Boolean).length <= limits.maxWords;
}

function validate() {
    clearErrors();

    const firstname = el.firstname.value.trim();
    const lastname = el.lastname.value.trim();
    const bad = [];

    if (!firstname || !validName(firstname)) bad.push(el.firstname);
    if (!lastname || !validName(lastname)) bad.push(el.lastname);

    if (bad.length > 0) {
        showError("name", text("error_name", "Letters and spaces only, up to {max} words per field.").replace("{max}", limits.maxWords), bad);
        return null;
    }

    const height = parseInt(el.height.value, 10);

    if (isNaN(height) || height < limits.minHeight || height > limits.maxHeight) {
        showError("height", text("error_height", "Height must be between {min} and {max} cm.").replace("{min}", limits.minHeight).replace("{max}", limits.maxHeight), [el.height]);
        return null;
    }

    if (!state.nationality) {
        showError("nationality", text("error_nationality", "Pick a nationality from the list."), [el.comboInput]);
        return null;
    }

    const day = parseInt(el.day.value, 10);
    const month = parseInt(el.month.value, 10);
    const year = parseInt(el.year.value, 10);

    if (isNaN(year) || year < limits.minYear || year > limits.maxYear) {
        showError("dob", text("error_year", "Birth year must be between {min} and {max}.").replace("{min}", limits.minYear).replace("{max}", limits.maxYear), [el.year]);
        return null;
    }

    if (isNaN(month) || month < 1 || month > 12) {
        showError("dob", text("error_month", "Month must be between 01 and 12."), [el.month]);
        return null;
    }

    if (isNaN(day) || day < 1 || day > daysInMonth(month, year)) {
        showError("dob", text("error_day", "That day does not exist in the selected month."), [el.day]);
        return null;
    }

    return {
        slot: state.selected,
        firstname: firstname,
        lastname: lastname,
        height: height,
        nationality: state.nationality,
        gender: state.gender,
        birthdate: year + "-" + pad(month) + "-" + pad(day)
    };
}

function setBusy(value) {
    state.busy = value;
    el.create.classList.toggle("busy", value);
}

function resetForm() {
    clearErrors();
    [el.firstname, el.lastname, el.height, el.day, el.month, el.year].forEach((input) => {
        input.value = "";
    });

    state.nationality = "";
    state.gender = 0;
    el.comboInput.value = "";
    el.combo.classList.remove("open");

    document.querySelectorAll(".pill").forEach((pill) => pill.classList.remove("active"));
    document.querySelector('.pill[data-sex="0"]').classList.add("active");
    setBusy(false);
}

function applyConfig(config) {
    if (!config) return;

    if (config.minHeight) limits.minHeight = config.minHeight;
    if (config.maxHeight) limits.maxHeight = config.maxHeight;
    if (config.minYear) limits.minYear = config.minYear;
    if (config.maxYear) limits.maxYear = config.maxYear;
    if (config.maxWords) limits.maxWords = config.maxWords;
    if (config.maxText) limits.maxText = config.maxText;

    el.height.placeholder = limits.minHeight + " - " + limits.maxHeight;
    el.firstname.maxLength = limits.maxText;
    el.lastname.maxLength = limits.maxText;
}

function openUI(data) {
    state.slots = data.slots || [];
    state.canDelete = data.canDelete === true;
    state.selected = data.selected || (state.slots[0] && state.slots[0].id) || 1;

    if (data.nations) state.nations = data.nations;
    applySound(data.sound);
    applyConfig(data.config);

    el.confirm.classList.remove("open");
    el.body.classList.remove("hidden");

    buildSlots();
    render();

    if (data.startCreate === true) {
        resetForm();
        el.back.classList.add("gone");
        showView("create");
        post("openCreate", { slot: state.selected, gender: state.gender });
        el.firstname.focus();
        return;
    }

    el.back.classList.remove("gone");
    showView("select");
}

function closeUI() {
    el.body.classList.add("hidden");
    el.confirm.classList.remove("open");
    setBusy(false);
}

async function localization() {
    try {
        const response = await fetch("./locales/language.json");
        const data = await response.json();

        Object.keys(data).forEach((key) => {
            locale[key] = data[key];

            document.querySelectorAll('[data-language="' + key + '"]').forEach((node) => {
                node.textContent = data[key];
            });

            document.querySelectorAll('[data-language-placeholder="' + key + '"]').forEach((node) => {
                node.placeholder = data[key];
            });
        });
    } catch (err) {
        return;
    }
}

el.play.addEventListener("click", () => {
    const slot = slotById(state.selected);
    if (!slot) return;

    if (slot.filled) {
        post("playCharacter", { slot: slot.id });
    } else {
        resetForm();
        showView("create");
        post("openCreate", { slot: slot.id, gender: state.gender });
        el.firstname.focus();
    }
});

el.del.addEventListener("click", () => {
    const slot = slotById(state.selected);
    if (!slot || !slot.filled || !state.canDelete) return;

    el.confirmText.textContent = text("confirm_text", "Character {name} will be permanently deleted along with all of their data.").replace("{name}", slot.firstname + " " + slot.lastname);
    el.confirm.classList.add("open");
});

document.getElementById("confirm-no").addEventListener("click", () => {
    el.confirm.classList.remove("open");
});

document.getElementById("confirm-yes").addEventListener("click", () => {
    const slot = slotById(state.selected);
    el.confirm.classList.remove("open");
    if (slot && slot.filled) post("deleteCharacter", { slot: slot.id });
});

document.getElementById("back").addEventListener("click", () => {
    showView("select");
    post("backToSelect", { slot: state.selected });
});

document.getElementById("reset").addEventListener("click", resetForm);

el.spawnConfirm.addEventListener("click", () => {
    if (state.busy) return;

    setBusy(true);
    post("confirmSpawn", { id: state.spawnSelected });
});

el.create.addEventListener("click", () => {
    if (state.busy) return;

    const payload = validate();
    if (!payload) return;

    setBusy(true);
    post("createCharacter", payload);
});

document.querySelectorAll(".ctrl").forEach((ctrl) => {
    ctrl.addEventListener("click", () => {
        step(parseInt(ctrl.dataset.step, 10));
    });
});

document.querySelectorAll(".pill").forEach((pill) => {
    pill.addEventListener("click", () => {
        const gender = parseInt(pill.dataset.sex, 10);
        if (state.gender === gender) return;

        document.querySelectorAll(".pill").forEach((node) => node.classList.remove("active"));
        pill.classList.add("active");
        state.gender = gender;
        section("sex").classList.remove("has-error");
        post("previewGender", { gender: gender });
    });
});

el.comboInput.addEventListener("focus", () => {
    el.combo.classList.add("open");
    renderCombo("");
});

el.comboInput.addEventListener("blur", () => {
    el.combo.classList.remove("open");
    el.comboInput.value = state.nationality;
});

el.comboInput.addEventListener("input", () => {
    el.combo.classList.add("open");
    renderCombo(el.comboInput.value);
});

el.comboInput.addEventListener("keydown", (event) => {
    const items = el.comboList.querySelectorAll(".combo-item");
    if (items.length === 0) return;

    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
        event.preventDefault();
        state.cursor = (state.cursor + (event.key === "ArrowDown" ? 1 : -1) + items.length) % items.length;
        items.forEach((item, i) => item.classList.toggle("cursor", i === state.cursor));
        items[state.cursor].scrollIntoView({ block: "nearest" });
        return;
    }

    if (event.key === "Enter" && state.cursor >= 0) {
        event.preventDefault();
        state.nationality = items[state.cursor].textContent;
        el.comboInput.value = state.nationality;
        el.combo.classList.remove("open");
        el.comboInput.blur();
    }
});

[el.height, el.day, el.month, el.year].forEach((input) => {
    input.addEventListener("input", () => {
        input.value = input.value.replace(/[^0-9]/g, "");
    });
});

[el.firstname, el.lastname].forEach((input) => {
    input.addEventListener("input", () => {
        input.value = input.value.replace(/[^A-Za-z ]/g, "");
    });
});

el.day.addEventListener("input", () => {
    if (el.day.value.length >= 2) el.month.focus();
});

el.month.addEventListener("input", () => {
    if (el.month.value.length >= 2) el.year.focus();
});

document.addEventListener("keydown", (event) => {
    if (el.body.classList.contains("hidden")) return;

    if (event.key === "Escape") {
        event.preventDefault();
        if (el.confirm.classList.contains("open")) el.confirm.classList.remove("open");
        return;
    }

    if (state.view === "spawn") {
        if (event.key === "ArrowUp") { event.preventDefault(); stepSpawn(-1); }
        if (event.key === "ArrowDown") { event.preventDefault(); stepSpawn(1); }
        if (event.key === "Enter") { event.preventDefault(); el.spawnConfirm.click(); }
        return;
    }

    if (state.view === "create") {
        if (event.key === "Enter" && document.activeElement !== el.comboInput) {
            event.preventDefault();
            el.create.click();
        }
        return;
    }

    if (el.confirm.classList.contains("open")) return;

    if (event.key === "ArrowLeft") {
        event.preventDefault();
        step(-1);
        return;
    }

    if (event.key === "ArrowRight") {
        event.preventDefault();
        step(1);
        return;
    }

    if (event.key === "Enter") {
        event.preventDefault();
        el.play.click();
    }
});

document.addEventListener("mouseover", (event) => {
    if (el.body.classList.contains("hidden")) return;
    if (!event.target || !event.target.closest) return;

    const target = event.target.closest(HOVER_TARGETS);

    if (!target) {
        sound.last = null;
        return;
    }

    if (target === sound.last || target.classList.contains("disabled")) return;

    sound.last = target;
    playHover();
});

document.addEventListener("click", (event) => {
    if (el.body.classList.contains("hidden")) return;
    if (!event.target || !event.target.closest) return;

    const target = event.target.closest(HOVER_TARGETS);

    if (!target || target.classList.contains("disabled")) return;

    playClick();
}, true);

document.addEventListener("pointerdown", unlockSound);
document.addEventListener("keydown", unlockSound);

window.addEventListener("message", (event) => {
    const data = event.data;

    if (data.action === "openui") {
        openUI(data);
        return;
    }

    if (data.action === "openspawn") {
        setBusy(false);
        openSpawn(data);
        return;
    }

    if (data.action === "closeui") {
        closeUI();
        return;
    }

    if (data.action === "createResult") {
        setBusy(false);
        if (!data.ok) showError("name", text("error_rejected", "The server rejected this data, check your entries again."));
    }
});

document.addEventListener("DOMContentLoaded", async () => {
    await localization();
    post("uiReady");
});
