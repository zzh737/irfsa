"""Explicit --self-test mode: exercise packaged GUI with a synthetic source only."""
import json
import sys
import tempfile
import time
from pathlib import Path
from backend import BASE
from ui_parameters import EXTRA_DEFAULTS, UI_MODES


def install(app):
    folder=BASE/'reports'
    folder.mkdir(exist_ok=True)
    app.settings=folder/'exe_smoke_settings.json'
    temporary=tempfile.TemporaryDirectory(prefix='ku5p_exe_smoke_')
    errors=[]
    started=time.monotonic()
    stage=0
    monitor_files={}
    analysis={}
    report=folder/'executable_smoke.json'
    if report.exists():
        report.unlink()
    app.report_callback_exception=lambda *args:errors.append(repr(args))

    def finish(error=None):
        result=dict(passed=not error and not errors,packaged=bool(getattr(sys,'frozen',False)),
                    demo_only=True,hardware_verified=False,error=error,callback_errors=errors,
                    live_monitor_and_record_handoff=stage>=14,
                    parallel_analysis_workers=analysis.get('worker_results',False),
                    packaged_model_inference=analysis.get('model_inference',False),
                    focused_layout_and_modulated_demo=stage>=5,
                    uart_udp_separation=stage>=2,
                    elapsed_seconds=time.monotonic()-started)
        report.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
        temporary.cleanup()
        app.close()

    def step():
        nonlocal stage,monitor_files
        try:
            if errors:
                raise RuntimeError(str(errors))
            if time.monotonic()-started>25:
                raise TimeoutError('Packaged GUI self-test timed out')
            if stage==0:
                assert len(UI_MODES)==20
                app.v['modulation'].set('256QAM')
                assert app.special_frames['am_depth'].winfo_manager()==''
                assert app.special_frames['rolloff'].winfo_manager()=='grid'
                for key,value in {**EXTRA_DEFAULTS,**dict(modulation='4PSK',center='2400',bandwidth='1',snr='10',atten1='20',atten2='30',
                                      noise_low='-0.5',noise_high='0.5',offset='0',seed='0x12345678',am_depth='0.5',
                                      rate='1 MSPS · FIR 抽取')}.items():
                    app.v[key].set(value)
                app.demo_choice.set(True)
                app.connect()
                stage=1
            elif stage==1 and app.connected and not app.pending:
                if not app.rx_connected:
                    assert str(app.rx_rate_entry.cget('state'))=='disabled'
                    assert not app.plot.available
                    assert str(app.upload_btn.cget('state'))=='normal'
                    app.connect_rx()
                    app.after(80,step)
                    return
                app.configure_radio()
                stage=2
            elif stage==2 and not app.pending:
                app.send('enable',tx1=True,tx2=True)
                stage=3
            elif stage==3 and not app.pending:
                assert app.last_tx['applied_mask']==3
                app.v['directory'].set(temporary.name)
                app.v['filename'].set('packaged_smoke')
                app.v['seconds'].set('1')
                app.record_switch.invoke()
                stage=4
            elif stage==4 and not app.pending and not app.recording:
                metadata=json.loads((Path(temporary.name)/'DEMO_packaged_smoke.json').read_text(encoding='utf-8'))
                assert metadata['simulated'] and metadata['stop_confirmed'] and metadata['file_bytes']>0
                assert app.plot.raw and app.last_tx['applied_mask']==3
                assert app.plot.context['modulation']=='4PSK'
                for kind in ('iq','constellation','spectrum'):
                    app.plot.focus(kind);app.update_idletasks()
                    panel=app.plot.panels[kind]
                    assert panel.winfo_width()>=app.plot.workspace.winfo_width()*.98
                    assert panel.winfo_height()>=app.plot.workspace.winfo_height()*.98
                    assert not app.parameter_pane.winfo_ismapped()
                    app.plot.overview();app.update_idletasks()
                    assert app.parameter_pane.winfo_ismapped()
                app.all_stop()
                stage=5
            elif stage==5 and not app.pending:
                assert app.last_tx['applied_mask']==0
                app.v['modulation'].set('64QAM')
                app.v['rx_gain_mode'].set('慢速 AGC');app.v['rx_bandwidth'].set('5')
                app.v['bandwidth'].set('0.2')
                app.configure_radio()
                stage=6
            elif stage==6 and not app.pending:
                app.send('enable',tx1=True,tx2=False)
                stage=7
            elif stage==7 and not app.pending:
                app.training_mode_btn.invoke()
                assert app.tabs.select()==str(app.training_tab)
                app.v['train_directory'].set(temporary.name)
                app.v['train_rate'].set('1 MSPS · FIR 抽取')
                app.v['train_seconds'].set('1')
                app.v['train_tag'].set('exe')
                app.training_switch.invoke()
                assert app.worker.training_lock.is_set()
                assert all(str(w.cget('state'))=='disabled' for w in app.edit_fields)
                stage=8
            elif stage==8 and app.recording:
                assert str(app.tx1_switch.cget('state'))=='disabled'
                assert app.tx1_switch.value is True and app.training_switch.value is True
                assert not app.send('enable',tx1=False)
                stage=9
            elif stage==9 and not app.pending and not app.recording:
                metadata=json.loads(app.last_capture_path.with_suffix('.json').read_text(encoding='utf-8'))
                assert metadata['training_mode'] and metadata['configuration_consistent']
                assert metadata['label']=='64QAM' and metadata['exclude_from_automatic_labeling']
                assert metadata['locked_configuration']['rx']['gain_mode']==1 if 'locked_configuration' in metadata else metadata['rx_gain_mode']==1
                assert metadata['file_bytes']>0 and app.last_tx['applied_mask']==1
                assert app.last_capture_path.name.startswith('DEMO_TRAIN_64QAM_')
                assert str(app.tx1_switch.cget('state'))=='normal'
                app.all_stop_btn.invoke()
                stage=10
            elif stage==10 and not app.pending:
                assert app.last_tx['applied_mask']==0
                monitor_files={p.name:p.stat().st_size for p in Path(temporary.name).iterdir()}
                app.monitor_switch.invoke()
                stage=11
            elif stage==11 and app.monitoring and app.plot.raw and len(app.plot.power):
                # Packaged analysis workers re-enter the EXE; results must still arrive.
                assert app.plot.pool.parallel,'analysis worker processes unavailable'
                analysis['worker_results']=True
                # Packaged ONNX inference in its own worker process (model optional on this PC).
                model=BASE/'model'/'v2_smoke_channel.onnx'
                if model.exists() and app.model_tester.load(model):
                    app.model_tester.live.set(True);app.model_tester.live_changed();analysis['model_loaded']=True
                assert not app.recording and not app.worker.recording
                assert monitor_files=={p.name:p.stat().st_size for p in Path(temporary.name).iterdir()}
                app.v['filename'].set('packaged_live_handoff')
                app.v['seconds'].set('0.6')
                app.record_switch.invoke()
                stage=12
            elif stage==12 and app.recording:
                assert not app.worker.monitoring
                assert str(app.monitor_switch.cget('state'))=='disabled'
                stage=13
            elif stage==13 and app.monitoring and not app.recording and not app.capture_pending:
                if analysis.get('model_loaded'):
                    assert app.model_tester.history or app.model_tester.live_label.cget('text').startswith('识别'),                        'packaged model inference produced no result'
                    analysis['model_inference']=True
                metadata=json.loads((Path(temporary.name)/'DEMO_packaged_live_handoff.json').read_text(encoding='utf-8'))
                assert metadata['file_bytes']>0 and metadata['stop_confirmed']
                app.all_stop_btn.invoke()
                stage=14
            elif stage==14 and not app.pending and not app.monitoring:
                assert not app.monitor_requested and app.last_tx['applied_mask']==0
                finish()
                return
        except Exception as exc:
            finish(str(exc))
            return
        app.after(80,step)
    app.after(200,step)
